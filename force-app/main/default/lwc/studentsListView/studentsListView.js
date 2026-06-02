import getStudents from '@salesforce/apex/StudentController.getStudents';
import { NavigationMixin } from 'lightning/navigation';
import { LightningElement, wire } from 'lwc';


export default class StudentsListView extends NavigationMixin(LightningElement) {
    students
    errorMsg

    @wire(getStudents) wiredStudents({ data, error }) {
        if (data) {
            if (data.length > 0) {
                this.students = data
                this.errorMsg = undefined
            } else {
                this.students = undefined
                this.errorMsg = 'No students found'
            }
        } else {
            this.students = undefined
            try {
                this.errorMsg = error.body.message
            } catch {
                this.errorMsg = 'Something went wrong, please try again.'
            }
        }
    }

    navigateToStudentDetail(event) {
        const recordId = event.currentTarget.dataset.id
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: recordId,
                objectApiName: 'Student__c',
                actionName: 'view'
            }
        })
    }

    navigateToCourseDetail(event) {
        const recordId = event.currentTarget.dataset.id
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: recordId,
                objectApiName: 'Course__c',
                actionName: 'view'
            }
        })
    }
}