import getStudentDetails from '@salesforce/apex/StudentController.getStudentDetails';
import { api, LightningElement, wire } from 'lwc';

export default class StudentDetailView extends LightningElement {
    @api recordId;
    student;
    errorMsg;

    @wire(getStudentDetails, { 'id': '$recordId' }) wiredStudentDetails({ data, error }) {
        console.log('recordId: ', this.recordId)
        // if (!this.recordId) return
        console.log('data coming: ', data)
        console.log('error coming: ', error)
        if (data) {
            this.student = data
            this.errorMsg = undefined
        } else {
            this.student = undefined
            try {
                this.errorMsg = error.body.message
            } catch (e) {
                console.log('error new coming: ', e)
                this.errorMsg = 'Something went wrong, please try again.'
            }
        }
    }
    connectedCallback() {
        console.log('connectedCallback recordId:', this.recordId);
    }

    renderedCallback() {
        console.log('renderedCallback recordId:', this.recordId);
    }
}