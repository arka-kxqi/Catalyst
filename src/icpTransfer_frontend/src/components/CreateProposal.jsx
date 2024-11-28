import React, { useState, useEffect } from 'react';
import { icpTransfer_backend } from '../../../declarations/icpTransfer_backend';
import {useNavigate} from "react-router-dom";
const CreateProposal = ({ notify, actor }) => {
  const navigate = useNavigate();
  const [formData, setFormData] = useState({
    name: '',
    title: '',
    description: '',
    goal: 0,
    image: null,
  });


  const handleChange = (e) => {
    const { name, value } = e.target;
    setFormData({
      ...formData,
      [name]: value,
    });
  };

  const handleFileChange = (e) => {
    const reader = new FileReader();
    console.log("first")
    reader.onloadend = async () => {
      const uri = reader.result;
      console.log(uri)
      const binary = convertDataURIToBinary(uri);
      setFormData({
        ...formData,
        image: binary,
      });
    };
    reader.readAsDataURL(e.target.files[0])
  };

  const convertDataURIToBinary = dataURI =>
    Uint8Array.from(window.atob(dataURI.replace(/^data[^,]+,/, '')), v => v.charCodeAt(0));


  const handleSubmit = async (e) => {
    e.preventDefault();
    if (actor !== null) {
      console.log(formData)
      if (formData.image) {
        try {
          console.log(formData.goal)
          const response = await actor.createProposal(formData.name, formData.title, formData.description, Math.round(formData.goal*(10**8)), formData.image);
          console.log('Proposal created:', response);
          if(response.ok){
            notify(`Proposal Created with id: ${Number(response.ok)}`);
            navigate("/proposals")
          }else{
            notify(response.err);
          }
        } catch (error) {
          console.error('Error creating proposal:', error);
          notify("Error creating proposal: ", error);
        }
      } else {
        console.error('No image file selected');
        notify("No image file selected");
      }
    } else {
      notify("Please Login To Continue")
    }
  };


  return (
    <div className="form-container">
      <button className="start-campaign-btn">Start a Proposal</button>
      <form onSubmit={handleSubmit}>
        <div className="form-group">
          <div className="form-field">
            <label>Your Name *</label>
            <input
              type="text"
              name="name"
              value={formData.name}
              onChange={handleChange}
              placeholder="John Doe"
              required
            />
          </div>
          <div className="form-field">
            <label>Campaign Title *</label>
            <input
              type="text"
              name="title"
              value={formData.title}
              onChange={handleChange}
              placeholder="Write a title"
              required
            />
          </div>
        </div>
        <div className="form-group">
          <label>Campaign Description*</label>
          <textarea
            name="description"
            value={formData.description}
            onChange={handleChange}
            placeholder="Write your Campaign Description"
            required
          />
        </div>
        <div className="info-banner">
          <p>You will get 100% of the raised amount</p>
        </div>
        <div className="form-group">
          <div className="form-field">
            <label>Goal *</label>
            <input
              type="number"
              step="0.0001"
              min="0"
              pattern="^\d*(\.\d{0,4})?$"
              placeholder="10.0000"
              name="goal"
              value={formData.goal}
              onChange={handleChange}
              required
            />
          </div>
        </div>
        <div className="form-group">
          <label>Campaign image *</label>
          <input
            type="file"
            name="image"
            accept='image/*'
            onChange={handleFileChange}
            required
          />
        </div>
        <button className="submit-btn" type="submit">Submit</button>
      </form>
    </div>
  );
};

export default CreateProposal;
