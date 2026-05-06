import { LightningElement } from 'lwc';
export default class HelloWorld extends LightningElement {
  greeting = 'Nasir';
  changeHandler(event) {
    this.greeting = event.target.value;
  }
}