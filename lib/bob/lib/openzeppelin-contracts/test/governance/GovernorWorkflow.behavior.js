const { expectRevert, time } = require('@openzeppelin/test-helpers');

async function getReceiptOrRevert (promise, error = undefined) {
  if (error) {
    await expectRevert(promise, error);
    return undefined;
  } else {
    const { receipt } = await promise;
    return receipt;
  }
}

function tryGet (obj, path = '') {
  try {
    return path.split('.').reduce((o, k) => o[k], obj);
  } catch (_) {
    return undefined;
  }
}

function zip (...args) {
  return Array(Math.max(...args.map(array => array.length)))
    .fill()
    .map((_, i) => args.map(array => array[i]));
}

function concatHex (...args) {
  return web3.utils.bytesToHex([].concat(...args.map(h => web3.utils.hexToBytes(h || '0x'))));
}

function runGovernorWorkflow () {
  beforeEach(async function () {
    this.receipts = {};

    // distinguish depending on the proposal length
    // - length 4: propose(address[], uint256[], bytes[], string) → GovernorCore
    // - length 5: propose(address[], uint256[], string[], bytes[], string) → GovernorCompatibilityBravo
    this.useCompatibilityInterface = this.settings.proposal.length === 5;

    // compute description hash
    this.descriptionHash = web3.utils.keccak256(this.settings.proposal.slice(-1).find(Boolean));

    // condensed proposal, used for queue and execute operation
    this.settings.shortProposal = [
      // targets
      this.settings.proposal[0],
      // values
      this.settings.proposal[1],
      // calldata (prefix selector if necessary)
      this.useCompatibilityInterface
        ? zip(
          this.settings.proposal[2].map(selector => selector && web3.eth.abi.encodeFunctionSignature(selector)),
          this.settings.proposal[3],
        ).map(hexs => concatHex(...hexs))
        : this.settings.proposal[2],
      // descriptionHash
      this.descriptionHash,
    ];

    // proposal id
    this.id = await this.mock.hashProposal(...this.settings.shortProposal);
  });

  it('run', async function () {
    // transfer tokens
    if (tryGet(this.settings, 'voters')) {
      for (const voter of this.settings.voters) {
        if (voter.weight) {
          await this.token.transfer(voter.voter, voter.weight, { from: this.settings.tokenHolder });
        } else if (voter.nfts) {
          for (const nft of voter.nfts) {
            await this.token.transferFrom(this.settings.tokenHolder, voter.voter, nft,
              { from: this.settings.tokenHolder });
          }
        }
      }
    }

    // propose
    if (this.mock.propose && tryGet(this.settings, 'steps.propose.enable') !== false) {
      this.receipts.propose = await getReceiptOrRevert(
        this.mock.methods[
          this.useCompatibilityInterface
            ? 'propose(address[],uint256[],string[],bytes[],string)'
            : 'propose(address[],uint256[],bytes[],string)'
        ](
          ...this.settings.proposal,
          { from: this.settings.proposer },
        ),
        tryGet(this.settings, 'steps.propose.error'),
      );

      if (tryGet(this.settings, 'steps.propose.error') === undefined) {
        this.deadline = await this.mock.proposalDeadline(this.id);
        this.snapshot = await this.mock.proposalSnapshot(this.id);
      }

      if (tryGet(this.settings, 'steps.propose.delay')) {
        await time.increase(tryGet(this.settings, 'steps.propose.delay'));
      }

      if (
        tryGet(this.settings, 'steps.propose.error') === undefined &&
        tryGet(this.settings, 'steps.propose.noadvance') !== true
      ) {
        await time.advanceBlockTo(this.snapshot.addn(1));
      }
    }

    // vote
    if (tryGet(this.settings, 'voters')) {
      this.receipts.castVote = [];
      for (const voter of this.settings.voters.filter(({ support }) => !!support)) {
        if (!voter.signature) {
          this.receipts.castVote.push(
            await getReceiptOrRevert(
              voter.reason
                ? this.mock.castVoteWithReason(this.id, voter.support, voter.reason, { from: voter.voter })
                : this.mock.castVote(this.id, voter.support, { from: voter.voter }),
              voter.error,
            ),
          );
        } else {
          const { v, r, s } = await voter.signature({ proposalId: this.id, support: voter.support });
          this.receipts.castVote.push(
            await getReceiptOrRevert(
              this.mock.castVoteBySig(this.id, voter.support, v, r, s),
              voter.error,
            ),
          );
        }
        if (tryGet(voter, 'delay')) {
          await time.increase(tryGet(voter, 'delay'));
        }
      }
    }

    // fast forward
    if (tryGet(this.settings, 'steps.wait.enable') !== false) {
      await time.advanceBlockTo(this.deadline.addn(1));
    }

    // queue
    if (this.mock.queue && tryGet(this.settings, 'steps.queue.enable') !== false) {
      this.receipts.queue = await getReceiptOrRevert(
        this.useCompatibilityInterface
          ? this.mock.methods['queue(uint256)'](
            this.id,
            { from: this.settings.queuer },
          )
          : this.mock.methods['queue(address[],uint256[],bytes[],bytes32)'](
            ...this.settings.shortProposal,
            { from: this.settings.queuer },
          ),
        tryGet(this.settings, 'steps.queue.error'),
      );
      this.eta = await this.mock.proposalEta(this.id);
      if (tryGet(this.settings, 'steps.queue.delay')) {
        await time.increase(tryGet(this.settings, 'steps.queue.delay'));
      }
    }

    // execute
    if (this.mock.execute && tryGet(this.settings, 'steps.execute.enable') !== false) {
      this.receipts.execute = await getReceiptOrRevert(
        this.useCompatibilityInterface
          ? this.mock.methods['execute(uint256)'](
            this.id,
            { from: this.settings.executer },
          )
          : this.mock.methods['execute(address[],uint256[],bytes[],bytes32)'](
            ...this.settings.shortProposal,
            { from: this.settings.executer },
          ),
        tryGet(this.settings, 'steps.execute.error'),
      );
      if (tryGet(this.settings, 'steps.execute.delay')) {
        await time.increase(tryGet(this.settings, 'steps.execute.delay'));
      }
    }
  });
}

module.exports = {
  runGovernorWorkflow,
};
