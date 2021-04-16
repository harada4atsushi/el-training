import App from '../components/HelloWorld'
import React from 'react'
import ReactDOM from 'react-dom'


document.addEventListener('turbolinks:load', () => {
// document.addEventListener('DOMContentLoaded', () => {
    const ele = document.getElementById('app')

    ReactDOM.render(
      <App greeting="Hello from react" />,
      ele
    )
  })
