import React, { useState } from 'react';

const UserSignup = () => {
  const [formData, setFormData] = useState({
    name: '',
    city: '',
    profilePic: null
  });

  const handleChange = (e) => {
    const { name, value } = e.target;
    setFormData({
      ...formData,
      [name]: value
    });
  };

  const handleFileChange = (e) => {
    setFormData({
      ...formData,
      profilePic: e.target.files[0]
    });
  };

  const handleSubmit = (e) => {
    e.preventDefault();
    // Handle form submission logic here
    console.log(formData);
  };

  return (
    <div style={{ padding: '20px', maxWidth: '600px', margin: 'auto' }}>
      <form
        onSubmit={handleSubmit}
        style={{
          border: '2px solid #17cf97',
          padding: '20px',
          borderRadius: '10px',
          color: 'white'
        }}
      >
        <div style={{ marginBottom: '15px' }}>
          <label>
            Name:
            <input
              type="text"
              name="name"
              value={formData.name}
              onChange={handleChange}
              style={{
                display: 'block',
                width: '100%',
                padding: '8px',
                margin: '8px 0',
                backgroundColor: 'lightgrey',
                border: 'none',
                borderRadius: '5px'
              }}
            />
          </label>
        </div>
        <div style={{ marginBottom: '15px' }}>
          <label>
            City:
            <input
              type="text"
              name="city"
              value={formData.city}
              onChange={handleChange}
              style={{
                display: 'block',
                width: '100%',
                padding: '8px',
                margin: '8px 0',
                backgroundColor: 'lightgrey',
                border: 'none',
                borderRadius: '5px'
              }}
            />
          </label>
        </div>
        <div style={{ marginBottom: '15px' }}>
          <label>
            Profile Picture:
            <input
              type="file"
              name="profilePic"
              onChange={handleFileChange}
              style={{
                display: 'block',
                margin: '8px 0',
                backgroundColor: 'lightgrey',
                border: 'none',
                borderRadius: '5px',
                color: 'white'
              }}
            />
          </label>
        </div>
        <button
          type="submit"
          style={{
            padding: '10px 20px',
            cursor: 'pointer',
            backgroundColor: '#17cf97',
            color: 'white',
            border: 'none',
            borderRadius: '5px'
          }}
        >
          Submit
        </button>
      </form>
    </div>
  );
};

export default UserSignup;
