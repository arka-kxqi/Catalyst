import React, { useEffect, useState } from 'react';
import { useParams } from 'react-router-dom';
import { Actor, HttpAgent } from '@dfinity/agent';
import { Principal } from '@dfinity/principal';
import { createActor, icpTransfer_backend } from "../../../declarations/icpTransfer_backend";
import ProgressBar from './utils/ProgressBar';

const DonateProposal = ({ actor, notify, principal }) => {
  const { id } = useParams();
  const [proposal, setProposal] = useState(null);
  const [amount, setAmount] = useState(''); // State to hold the input value
  const [claimPrincipal, setClaimPrincipal] = useState("");
  function handleChange() {

  }

  async function bufferToBase64(buffer) {
    // use a FileReader to generate a base64 data URI:
    const base64url = await new Promise(r => {
      const reader = new FileReader()
      reader.onload = () => r(reader.result)
      reader.readAsDataURL(new Blob([buffer]))
    });
    // remove the `data:...;base64,` part from the start
    return base64url.slice(base64url.indexOf(',') + 1);
  }

  useEffect(() => {
    const fetchProposal = async () => {
      if (id) {
        if (actor !== null) {
          console.log(actor)
          const res = await actor.getProposal(Number(id));
          console.log(res)
          if (res.ok) {
            var val = res.ok;
            var b64 = "data:image/webp;base64," + await bufferToBase64(val.image);
            const prop = { ...val, image: b64, created_by_text: Principal.from(val.created_by).toString(), amount_required: Number(val.amount_required) / 10 ** 8, amount_raised: Number(val.amount_raised) / 10 ** 8 };
            console.log(prop)
            setProposal(prop)
          } else {
            notify(res.err)
          }
        } else {
          notify("Please Login To Continue")
        }
      } else {
        notify("Invalid Proposal ID")
      }

    };

    fetchProposal();
  }, [actor]);

  const handleInputChange = (e) => {
    setAmount(e.target.value);
  };

  const handleClaimInputChange = (e) => {
    setClaimPrincipal(e.target.value);
  };

  // Function to handle button click
  const handleButtonClick = async () => {
    if (amount) {
      console.log(`Funding campaign with amount: ${amount}`);
      if (amount > proposal.amount_required - proposal.amount_raised) {
        notify(`Amount Must not exceed ${proposal.amount_required - proposal.amount_raised} ICP`)
        return;
      }
      try {
        const params = {
          to: proposal.accountId,
          amount: Math.round(amount * (10 ** 8)),
          memo: '123451231231',
        };
        const result = await window.ic.plug.requestTransfer(params);
        console.log(result)
        if (result.height.height) {
          notify("Syncing Initiated");
          const syn = await icpTransfer_backend.syncTransactions(Number(id));
          if (syn.ok) {
            notify("Syncing Finished");
            var val = syn.ok;
            var b64 = "data:image/webp;base64," + await bufferToBase64(val.image);
            const prop = { ...val, image: b64, created_by_text: Principal.from(val.created_by).toString(), amount_required: Number(val.amount_required) / 10 ** 8, amount_raised: Number(val.amount_raised) / 10 ** 8 };
            console.log(prop)
            setProposal(prop)
          } else {
            notify("syncing Failed")
          }
        }
      } catch (e) {
        console.log(e)
        notify("Transfer Attempt Failed: ", e.message)
      }
    } else {
      notify('Please enter a valid amount');
    }
  };

  const handleClaimClick = async () => {
    try{
      var res_principal = Principal.fromText(claimPrincipal);
    }
    catch(e){
      notify(`Invalid Principal : ${claimPrincipal}`)
      return;
    }
    const result = await actor.claimProposal(Number(id),res_principal)
    console.log(result);
    if(result.ok){
      notify(`Sent Funds to ${res_principal.toString()}`);
    }else{
      notify(`Error Occurred: ${result.err}`)
    }
  }

  if (!proposal) {
    return <div>Loading...</div>;
  }


  return (
    <div className="proposal-details">
      <div className="left-section">
        <div className="proposal-image-section">
          <img
            src={proposal.image}
            alt='Proposal'
          />
        </div>

        <div className="proposal-meta">
          <p><div></div>
            <div></div>
            {proposal.title}</p>
          <p>By - {proposal.name}</p>
          <div className="proposal-story">
            <p>Story: <div></div>
              <div></div>
              {proposal.description}</p>
          </div>

        </div>
      </div>

      <div className="right-section">
        <div >
          <br></br>
          <label htmlFor="rangeBar" style={{ marginBottom: "10px", display: "block" }}>
            Goal {proposal.amount_required} ICP
          </label>
          <label htmlFor="rangeBar" style={{ marginBottom: "10px", display: "block" }}>
            Raised {proposal.amount_raised} ICP
          </label>
          <ProgressBar progress={(proposal.amount_raised / proposal.amount_required) * 100} />
          {proposal.amount_required - proposal.amount_raised == 0 && <div>Goal Reached</div>}
          {proposal.amount_required - proposal.amount_raised == 0 && proposal.claimed && <div>Funds Claimed</div>}

        </div>

        {proposal.amount_required - proposal.amount_raised == 0 && proposal.created_by_text == principal && !proposal.claimed && <div className="proposal-funding">
          <p><strong>Claim Funds ({proposal.amount_raised} ICP)</strong></p>
          <input type="text" placeholder="xxxx-xxxx-xxxx-xxxx" value={claimPrincipal}
            onChange={handleClaimInputChange} />
          <button onClick={handleClaimClick} className="fund-button">Claim</button>
        </div>}


        {proposal.amount_required - proposal.amount_raised > 0 && <div className="proposal-funding">
          <p><strong>Donate</strong></p>
          <input type="number" placeholder="0.0001" min="0.0001" max={proposal.amount_required - proposal.amount_raised} step="0.0001" value={amount}
            onChange={handleInputChange} />
          <button onClick={handleButtonClick} className="fund-button">Fund Campaign</button>
        </div>}


        <div className="proposal-donators">
          <p><strong>Donators:</strong></p>
          {proposal.donations.map((donation, index) => {
            return <div><>{donation.account}</><br></br><strong>Amount: </strong><>{Number(donation.amount.e8s) / 10 ** 8}</><br></br><strong>Click To Verify Transaction: </strong><a style={{color:'orange',textDecoration:'none'}} target='_blank' href={"https://dashboard.internetcomputer.org/transaction/" + Number(donation.transaction_id)}>{Number(donation.transaction_id)}</a><br></br><br></br></div>
          })}
        </div>


      </div>
    </div>
  );
};

export default DonateProposal;
