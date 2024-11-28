import React, { useState, useEffect } from "react";
import { canisterId } from '../../../declarations/icpTransfer_backend';
import { Link, useNavigate } from 'react-router-dom';
import { ConnectBtn } from "./ConnectBtn";

const Navbar = ({ isConnected, principal, setPrincipal, setAccountId, setIsConnected, setActor }) => {
  const [clicked, setClicked] = useState(false);
  const navigate = useNavigate();

  const handleAuthenticatedClick = async (link) => {
    try {
      if (!isConnected) {
        const publicKey = await window.ic.plug.requestConnect({ whitelist: [canisterId] })
        const connected = await window.ic.plug.isConnected();
        setIsConnected(connected)
        if (connected) {
          setPrincipal(window.ic.plug.principalId)
          setAccountId(window.ic.plug.accountId)
          const actor = await window.ic.plug.createActor({ canisterId: canisterId, interfaceFactory: idlFactory });
          setActor(actor)
          navigate(link);
        }
      } else {
        navigate(link);
      }
    } catch (e) {
      console.log(e);
    }

  }

  const handleClick = () => {
    setClicked(!clicked);
  };

  return (
    <>
      <nav>
        <Link to="/">
          <img src="logo2.png" alt="Logo" className="logo" />
        </Link>

        <div>
          <ul id="navbar" className={clicked ? "#navbar active" : "#navbar"}>
            <li id="btn">
              <Link id="btn" to="/">Home</Link>
            </li>

            <li id="btn" className="dropdown">
              Proposals
              <ul className="dropdown-content">
                <li id="btn">
                  <a id="btn" onClick={(e) => handleAuthenticatedClick("/createproposal")}>Create Proposals </a>
                </li>
                <br />
                <li id="btn">
                  <a id="btn" onClick={(e) => handleAuthenticatedClick("/proposals")}>My Proposals </a>
                </li>
              </ul>
            </li>

            <li id="btn">
              <Link id="btn" to="/explore">All Proposals</Link>
            </li>
            {/* <li id="btn">
              <a id="btn" onClick={(e) => handleAuthenticatedClick("/profile")}>Profile</a>
            </li> */}

            <div className="plug">
              <ConnectBtn isConnected={isConnected} principal={principal} setPrincipal={setPrincipal} setAccountId={setAccountId} setIsConnected={setIsConnected} setActor={setActor} />
            </div>
          </ul>
        </div>

        <div id="mobile" onClick={handleClick}>
          <i
            id="bar"
            className={clicked ? "fas fa-times" : "fas fa-bars"}
          ></i>
        </div>
      </nav>
    </>
  );
};

export default Navbar;
