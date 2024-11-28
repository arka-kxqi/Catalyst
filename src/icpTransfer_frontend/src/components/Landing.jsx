import React from 'react';




const Landing = () => {
  return (
    <div className="landing-page">
    <div className="homepage-container">
     <header className="header">
       <h1 className="title">FactFund</h1>
       <p className="sub-description">
         Fund dedicated to verifying, supporting, or promoting factual information.
       </p>
     </header>
   </div>
       <div className='why'>
        <h2>Why FactFund?</h2><br></br>
        
        <p>Traditional crowdfunding platforms often fall short when it comes to transparency, democratic decision-making, and proper tracking of funds.</p> 
        <p>FactFund addresses these issues by leveraging the power of the Internet Computer Protocol (ICP) blockchain to create a decentralized, transparent, and secure crowdfunding platform.</p>
      </div>
      <br></br>
      <div className="cards-container">
        <div className="card2">
            <img src="decen2 .png" alt="Decentralization" />
            <h3>Decentralization</h3>
           
            <p> FactFund operates on a decentralized platform, removing the need for intermediaries and ensuring that all decisions are made by the community, fostering trust and autonomy.</p>
          </div>
          
          <div className="card2">
            <img src="trans.png" alt="transperancy" />
            <h3>Transparency</h3>
            <p>By leveraging the ICP blockchain, FactFund provides complete transparency in fund management, allowing users to track every transaction and see exactly how funds are being utilized.</p>
          </div>
          <div className="card2">
            <img src="security.png" alt="Security" />
            <h3>Security</h3>
            <p> FactFund ensures tamper-proof and secure transactions through the use of blockchain technology and the Plug wallet, protecting user data and funds from fraud and unauthorized access.</p>
          </div>
          <div className="card2">
            <img src="fee.png" alt="Low Fees" />
            <h3>No Hidden Fee</h3>
            <p>Our platform offers no transaction fees, making it cost-effective for users to donate and participate in funding projects, ensuring that more of your contributions go directly to the causes you support.</p>
          </div>
          <div className="card2">
            <img src="dao.png" alt="dao" />
            <h3>DAO</h3>
            <p>Decentralized Autonomous Organization empowers the community to govern the platform, enabling users to vote on proposals and make collective decisions on fund allocation.</p>
          </div>
        </div>
      <br></br>
      <br></br>
   
      <div className='usecase'> 
        <h2>Use Cases</h2>
        <br></br>
          <li><strong>Non-Profit Projects:</strong> Support social and charitable projects, provide disaster relief funds, promote pet adoption and feeding initiatives, contribute to temple funds, and other community-driven causes. ❤️</li>
          <br></br>
          
          <li style={{paddingRight: 635}}><strong>Community Initiatives:</strong> Support local projects that drive community engagement and development. 🌱</li>
        
      </div>
      
    
    
      <footer className="footer">
        <h2>Join Us Today</h2>
         <br></br>
        <p style={{paddingRight : 100}}>Be part of a revolutionary change in crowdfunding. Support the campaigns or proposals you believe in, track your donations, and be assured of transparent and democratic decision-making.</p>
        <br></br>
        <div className='social' style={{justifyContent : 'space-between'}}>
        <a href='https://x.com/fact_fund'> <img src='twitter.png' alt='twitter' style={{width : 40 , height : 40 }}></img> </a>
        <a href='https://www.linkedin.com/company/factfund/'> <img src='linkedin.png' alt='linkedin' style={{width : 40 , height : 40}}></img> </a>
        <a href='https://www.instagram.com/factfund.io/'> <img src='instagram.png' alt='insta'style={{width : 40 , height : 40}} ></img> </a>
        </div>
        <br>
        </br>
      </footer>
    </div>
  );
};

export default Landing;
