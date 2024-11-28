import IcpLedger "canister:icp_ledger_canister";
import LedgerIndex "canister:icp_index_canister";
import Debug "mo:base/Debug";
import Result "mo:base/Result";
import Blob "mo:base/Blob";
import Error "mo:base/Error";
import Array "mo:base/Array";
import Principal "mo:base/Principal";
import Nat64 "mo:base/Nat64";
import Nat8 "mo:base/Nat8";
import Text "mo:base/Text";
import Buffer "mo:base/Buffer";
import Bool "mo:base/Bool";
import Map "mo:map/Map";
import Hex "mo:encoding/Hex";
import Vector "mo:vector";
import { thash } "mo:map/Map";

actor IcpTransfer_backend {

    type Tokens = {
        e8s : Nat64;
    };

    type Donation = {
        account : Text;
        amount : Tokens;
        transaction_id : Nat64;
    };

    type User = {
        created_proposals : [Nat64];
        donated_proposals : [Nat64];
    };

    type Proposal = {
        index : Nat64;
        name : Text;
        title : Text;
        description : Text;
        amount_required : Nat64;
        image : Blob;
        subaccount : Blob;
        accountId : Text;
        created_by : Principal;
        donations : [Donation];
        synced_upto : Nat64;
        amount_raised : Nat64;
        claimed : Bool;
    };

    type Vector<Proposal> = {
        var data_blocks : [var [var ?Proposal]];
        var i_block : Nat;
        var i_element : Nat;
    };

    type HashUtils<Principal> = (
        getHash : (Principal) -> Nat32,
        areEqual : (Principal, Principal) -> Bool,
    );

    stable var users = Map.new<Text, User>();
    stable var proposals : Vector<Proposal> = Vector.new<Proposal>();

    type TransferArgs = {
        amount : Tokens;
        toPrincipal : Principal;
        toSubaccount : ?Blob;
    };

    private func fromNat(len : Nat, n : Nat) : [Nat8] {
        let ith_byte = func(i : Nat) : Nat8 {
            assert (i < len);
            let shift : Nat = 8 * (len - 1 - i);
            Nat8.fromIntWrap(n / 2 ** shift);
        };
        Array.tabulate<Nat8>(len, ith_byte);
    };

    private func fromNat64(n : Nat64) : [Nat8] {
        fromNat(32, Nat64.toNat(n));
    };

    public func createProposal(name : Text, title : Text, description : Text, amount_required : Nat64, image : Blob) : async Result.Result<Nat, Text> {
        let caller = Principal.fromText("recv4-pufm4-ddgc3-m6whc-kh75g-hfklr-oj46z-bxn2y-coejw-xt5kw-xae");
        let proposal_size = Vector.size<Proposal>(proposals);
        let proposal_subaccount = Blob.fromArray(fromNat64(Nat64.fromNat(proposal_size)));
        let current_round = (await LedgerIndex.status()).num_blocks_synced - 1;
        let newProposal : Proposal = {
            name = name;
            title = title;
            description = description;
            amount_required = amount_required;
            image = image;
            subaccount = proposal_subaccount;
            created_by = caller;
            donations = [];
            synced_upto = current_round;
            accountId = Text.toLowercase(Hex.encode(Blob.toArray(Principal.toLedgerAccount(Principal.fromActor(IcpTransfer_backend), ?proposal_subaccount))));
            amount_raised = 0;
            claimed = false;
            index = Nat64.fromNat(proposal_size);
        };
        Vector.add<Proposal>(proposals, newProposal);
        addCreatedProposalToUsers(caller, Nat64.fromNat(proposal_size));
        return #ok(proposal_size);
    };

    public func getProposal(id : Nat) : async Result.Result<Proposal, Text> {
        var size = Vector.size<Proposal>(proposals);
        if (id >= size) {
            return #err("No Proposal is available with this id");
        } else {
            var proposal = Vector.getOpt<Proposal>(proposals, id);
            switch (proposal) {
                case (null) {
                    return #err("No Proposal is available with this id");
                };
                case (?proposal) {
                    switch (await syncTransactions(id)) {
                        case (#ok proposal) {
                            return #ok(proposal);
                        };
                        case (#err message) {
                            return #err("Error Occured While Syncing Transactions: " #message);
                        };
                    };
                };
            };
        };
    };

    public func accountIdent(id : Nat) : async Result.Result<Text, Text> {
        var size = Vector.size<Proposal>(proposals);
        if (id >= size) {
            return #err("No Proposal is available with this id");
        } else {
            var proposal = Vector.getOpt<Proposal>(proposals, id);
            switch (proposal) {
                case (null) {
                    return #err("No Proposal is available with this id");
                };
                case (?proposal) {
                    var account = Principal.toLedgerAccount(Principal.fromActor(IcpTransfer_backend), ?proposal.subaccount);
                    var balance = await IcpLedger.account_balance({
                        account = account;
                    });
                    var accid = Text.toLowercase(Hex.encode(Blob.toArray(account)));
                    Debug.print(debug_show (account) # debug_show (balance) # debug_show (accid) # debug_show(Principal.fromActor(IcpTransfer_backend)));
                    return #ok("knk");
                };
            };
        };
    };

    public func actorAccount() : async Text {
        return Hex.encode(Blob.toArray(Principal.toLedgerAccount(Principal.fromActor(IcpTransfer_backend),null)));
    };

    public query func getLatestProposals(len : Nat) : async Result.Result<[Proposal], Text> {
        var size = Vector.size<Proposal>(proposals);
        if (size > 0) {
            var arr = Vector.toArray<Proposal>(proposals);
            if (size > len) {
                var res = Array.subArray<Proposal>(arr, size -len, len);
                return #ok(res);
            } else {
                return #ok(arr);
            };
        } else {
            return #ok([]);
        };
    };

    public query func getLatestMyProposals(len : Nat) : async Result.Result<[Proposal], Text> {
        let caller = Principal.fromText("recv4-pufm4-ddgc3-m6whc-kh75g-hfklr-oj46z-bxn2y-coejw-xt5kw-xae");
        var size = Vector.size<Proposal>(proposals);
        if (size > 0) {
            var arr = Vector.toArray<Proposal>(proposals);
            var r_len = 0;
            switch (Map.get<Text, User>(users, thash, Text.toLowercase(Hex.encode(Blob.toArray(Principal.toLedgerAccount(caller, null)))))) {
                case (null) {
                    return #ok([]);
                };
                case (?user) {
                    var props = Buffer.Buffer<Proposal>(3);
                    var created_proposals = user.created_proposals;
                    for (pid in created_proposals.vals()) {
                        if (r_len < len) {
                            r_len := r_len +1;
                            props.add(arr[Nat64.toNat(pid)]);
                        };
                    };
                    return #ok(Buffer.toArray<Proposal>(props));
                };
            };
        } else {
            return #ok([]);
        };
    };

    public query func getProposalsLength() : async Nat {
        var size = Vector.size<Proposal>(proposals);
        return size;
    };

    public func syncTransactions(proposalId : Nat) : async Result.Result<Proposal, Text> {
        var size = Vector.size<Proposal>(proposals);
        if (proposalId >= size) {
            return #err("No Proposal is available with this id");
        } else {
            var proposal = Vector.getOpt<Proposal>(proposals, proposalId);
            switch (proposal) {
                case (null) {
                    return #err("No Proposal is available with this id");
                };
                case (?proposal) {
                    let current_round = (await LedgerIndex.status()).num_blocks_synced;
                    var synced_upto = proposal.synced_upto;
                    var mx_res = current_round -synced_upto;
                    var proposal_subaccount = proposal.subaccount;
                    var cannister_principal = Principal.fromActor(IcpTransfer_backend);
                    var proposal_account_identifier = Principal.toLedgerAccount(cannister_principal, ?proposal_subaccount);
                    var proposal_account_identifier_text = Text.toLowercase(Hex.encode(Blob.toArray(proposal_account_identifier)));
                    let transactions = await LedgerIndex.get_account_identifier_transactions({
                        max_results = mx_res;
                        start = ?current_round;
                        account_identifier = proposal_account_identifier_text;
                    });
                    Debug.print(
                        "max_res "
                        # debug_show (mx_res)
                        # " current_round "
                        # debug_show (current_round)
                        # " account "
                        # debug_show (proposal_account_identifier_text)
                        # "synced_upto"
                        # debug_show (synced_upto)
                    );
                    switch (transactions) {
                        case (#Ok response) {
                            var txns = response.transactions;
                            let buf_txns = Buffer.fromArray<LedgerIndex.TransactionWithId>(txns);
                            var new_amount_raised : Nat64 = proposal.amount_raised;
                            var new_donations = Buffer.Buffer<Donation>(3);
                            Debug.print(
                                " buff "
                                # debug_show (Buffer.toArray<LedgerIndex.TransactionWithId>(buf_txns))
                            );
                            Buffer.iterate<LedgerIndex.TransactionWithId>(
                                buf_txns,
                                func(txn : LedgerIndex.TransactionWithId) {
                                    switch (txn.transaction.operation) {
                                        case (#Transfer txn_params) {
                                            if (Text.toUppercase(txn_params.to) == Text.toUppercase(proposal_account_identifier_text)) {
                                                if (txn.id > synced_upto) {
                                                    var new_donation : Donation = {
                                                        account = txn_params.from;
                                                        amount = txn_params.amount;
                                                        transaction_id = txn.id;
                                                    };
                                                    new_donations.add(new_donation);
                                                    new_amount_raised := new_amount_raised + txn_params.amount.e8s;
                                                    addDonatedProposalToUsers(txn_params.from, Nat64.fromNat(proposalId));
                                                };
                                            };
                                        };
                                        case (#Approve _txn_params) {
                                            return ();
                                        };
                                        case (#Burn _txn_params) {
                                            return ();
                                        };
                                        case (#Mint _txn_params) {
                                            return ();
                                        };
                                    };
                                },
                            );
                            var old_donations = Buffer.fromArray<Donation>(proposal.donations);
                            old_donations.append(new_donations);
                            var new_proposal : Proposal = {
                                name = proposal.name;
                                title = proposal.title;
                                description = proposal.description;
                                amount_required = proposal.amount_required;
                                image = proposal.image;
                                subaccount = proposal.subaccount;
                                created_by = proposal.created_by;
                                donations = Buffer.toArray(old_donations);
                                synced_upto = current_round -1;
                                accountId = proposal.accountId;
                                amount_raised = new_amount_raised;
                                claimed = false;
                                index = proposal.index;
                            };
                            Vector.put<Proposal>(proposals, proposalId, new_proposal);
                            return #ok(new_proposal);
                        };
                        case (#Err error) {
                            return #err(error.message);
                        };
                    };

                };
            };
        };
    };

    public shared ({caller}) func claimProposal(proposalId : Nat, p : Principal) : async Result.Result<IcpLedger.BlockIndex, Text> {
        let caller = Principal.fromText("recv4-pufm4-ddgc3-m6whc-kh75g-hfklr-oj46z-bxn2y-coejw-xt5kw-xae");
        var size = Vector.size<Proposal>(proposals);
        if (proposalId >= size) {
            return #err("No Proposal is available with this id");
        } else {
            var proposal = Vector.getOpt<Proposal>(proposals, proposalId);
            switch (proposal) {
                case (null) {
                    return #err("No Proposal is available with this id");
                };
                case (?proposal) {
                    switch (await syncTransactions(proposalId)) {
                        case (#ok proposal) {
                            if (proposal.created_by == caller) {
                                if (proposal.amount_raised >= proposal.amount_required) {
                                    if (not proposal.claimed) {
                                        var amount = proposal.amount_raised - 10_000;
                                        var subaccount = proposal.subaccount;
                                        let transferArgs : IcpLedger.TransferArgs = {
                                            memo = 999;
                                            amount = {
                                                e8s = amount;
                                            };
                                            fee = { e8s = 10_000 };
                                            from_subaccount = ?subaccount;
                                            to = Principal.toLedgerAccount(p, null);
                                            created_at_time = null;
                                        };
                                        Debug.print(
                                            debug_show (subaccount) #
                                            debug_show (transferArgs)
                                        );
                                        let transferResult = await IcpLedger.transfer(transferArgs);
                                        Debug.print(
                                            debug_show (transferResult)
                                        );
                                        switch (transferResult) {
                                            case (#Err(transferError)) {
                                                return #err("Couldn't transfer funds:\n" # debug_show (transferError));
                                            };
                                            case (#Ok(blockIndex)) {
                                                var new_proposal = {
                                                    name = proposal.name;
                                                    title = proposal.title;
                                                    description = proposal.description;
                                                    amount_required = proposal.amount_required;
                                                    image = proposal.image;
                                                    subaccount = proposal.subaccount;
                                                    created_by = proposal.created_by;
                                                    donations = proposal.donations;
                                                    synced_upto = proposal.synced_upto;
                                                    amount_raised = proposal.amount_raised;
                                                    accountId = proposal.accountId;
                                                    claimed = true;
                                                    index = proposal.index;
                                                };
                                                Vector.put<Proposal>(proposals, proposalId, new_proposal);
                                                return #ok(blockIndex);
                                            };
                                        };
                                    } else {
                                        return #err("Already Funds are Claimed");
                                    };
                                } else {
                                    return #err("Cannot Claim Without raising required amount");
                                };
                            } else {
                                return #err("Only Proposal Creator Can Call this Method");
                            };
                        };
                        case (#err message) {
                            return #err("Error Occured While Syncing Transactions: " #message);
                        };
                    };
                };
            };
        };
    };

    private func addCreatedProposalToUsers(principal : Principal, proposalId : Nat64) : () {
        switch (Map.get<Text, User>(users, thash, Text.toLowercase(Hex.encode(Blob.toArray(Principal.toLedgerAccount(principal, null)))))) {
            case (null) {
                var new_user : User = {
                    created_proposals = [proposalId];
                    donated_proposals = [];
                };
                Map.set<Text, User>(users, thash, Text.toLowercase(Hex.encode(Blob.toArray(Principal.toLedgerAccount(principal, null)))), new_user);
            };
            case (?user) {
                var new_created_proposals = Buffer.fromArray<Nat64>(user.created_proposals);
                switch (Buffer.indexOf<Nat64>(proposalId, new_created_proposals, Nat64.equal)) {
                    case (null) {
                        new_created_proposals.add(proposalId);
                        var new_user : User = {
                            created_proposals = Buffer.toArray(new_created_proposals);
                            donated_proposals = user.donated_proposals;
                        };
                        Map.set<Text, User>(users, thash, Text.toLowercase(Hex.encode(Blob.toArray(Principal.toLedgerAccount(principal, null)))), new_user);
                    };
                    case (?_index) {
                        return ();
                    };
                };
            };
        };
    };

    private func addDonatedProposalToUsers(account : Text, proposalId : Nat64) : () {
        switch (Map.get<Text, User>(users, thash, account)) {
            case (null) {
                var new_user : User = {
                    created_proposals = [];
                    donated_proposals = [proposalId];
                };
                Map.set<Text, User>(users, thash, account, new_user);
            };
            case (?user) {
                var new_donated_proposals = Buffer.fromArray<Nat64>(user.donated_proposals);
                switch (Buffer.indexOf<Nat64>(proposalId, new_donated_proposals, Nat64.equal)) {
                    case (null) {
                        new_donated_proposals.add(proposalId);
                        var new_user : User = {
                            created_proposals = user.created_proposals;
                            donated_proposals = Buffer.toArray(new_donated_proposals);
                        };
                        Map.set<Text, User>(users, thash, account, new_user);
                    };
                    case (?_index) {
                        return ();
                    };
                };
            };
        };
    };

    public shared ({ caller }) func checkPrincipal() : async Text {
        return Principal.toText(caller);
    };

    public func transfer(args : TransferArgs) : async Result.Result<IcpLedger.BlockIndex, Text> {
        Debug.print(
            "Transferring "
            # debug_show (args.amount)
            # " tokens to principal "
            # debug_show (args.toPrincipal)
            # " subaccount "
            # debug_show (args.toSubaccount)
        );

        let transferArgs : IcpLedger.TransferArgs = {
            // can be used to distinguish between transactions
            memo = 0;
            // the amount we want to transfer
            amount = args.amount;
            // the ICP ledger charges 10_000 e8s for a transfer
            fee = { e8s = 10_000 };
            // we are transferring from the canisters default subaccount, therefore we don't need to specify it
            from_subaccount = null;
            // we take the principal and subaccount from the arguments and convert them into an account identifier
            to = Principal.toLedgerAccount(args.toPrincipal, args.toSubaccount);
            // a timestamp indicating when the transaction was created by the caller; if it is not specified by the caller then this is set to the current ICP time
            created_at_time = null;
        };

        try {
            // initiate the transfer
            let transferResult = await IcpLedger.transfer(transferArgs);

            // check if the transfer was successfull
            switch (transferResult) {
                case (#Err(transferError)) {
                    return #err("Couldn't transfer funds:\n" # debug_show (transferError));
                };
                case (#Ok(blockIndex)) { return #ok blockIndex };
            };
        } catch (error : Error) {
            // catch any errors that might occur during the transfer
            return #err("Reject message: " # Error.message(error));
        };
    };

    type AccountBalanceArgs = {
        account : IcpLedger.AccountIdentifier;
    };

    public shared ({ caller }) func balance() : async Result.Result<Tokens, Text> {
        let args : AccountBalanceArgs = {
            account = Principal.toLedgerAccount(caller, null);
        };
        let res = await IcpLedger.account_balance(args);
        #ok(res);
    };

};
