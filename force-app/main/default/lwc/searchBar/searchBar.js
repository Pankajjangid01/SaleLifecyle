import { LightningElement, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import getChain from '@salesforce/apex/LifecycleTrackerController.getChain';

export default class SearchBar extends NavigationMixin(LightningElement) {

    @track searchId = '';
    @track isLoading = false;
    @track errorMessage = '';
    @track chainData = [];

    get hasError() {
        return !!this.errorMessage;
    }

    get hasData() {
        return this.chainData && this.chainData.length > 0;
    }

    handleSearchInput(event) {
        this.searchId = event.target.value;
    }

    handleSearch() {
        if (!this.searchId || !this.searchId.trim()) {
            return;
        }
        this.isLoading = true;
        this.errorMessage = '';
        this.chainData = [];
        getChain({ searchId: this.searchId.trim() })
            .then(result => {
                const items = Array.isArray(result) ? result : [result];
                this.chainData = items.map((item, idx) => {
                    item._computedKey = this.getItemKey(item, idx);
                    return item;
                });
            })
            .catch(error => {
                this.errorMessage = error?.body?.message || 'An unexpected error occurred.';
            })
            .finally(() => {
                this.isLoading = false;
            });
    }

    viewRecord(recordId, objectName) {
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: recordId,
                objectApiName: objectName,
                actionName: 'view'
            }
        });
    }

    getItemKey(item, index) {
        if (item?.opportunity?.Id) return item.opportunity.Id;
        if (item?.invoiceRecord?.Id) return item.invoiceRecord.Id;
        if (item?.lead?.Id) return item.lead.Id;
        if (item?.quoteRecord?.Id) return item.quoteRecord.Id;
        return 'item_' + index;
    }

    viewLead(event) {
        const index = event.currentTarget.dataset.index;
        const leadId = this.chainData[index]?.lead?.Id;
        if (leadId) {
            this.viewRecord(leadId,'Lead');
        }
    }

    viewOpportunity(event) {
        const index = event.currentTarget.dataset.index;
        const oppId = this.chainData[index]?.opportunity?.Id;
        if (oppId) {
            this.viewRecord(oppId,'Opportunity');
        }
    }

    viewQuote(event) {
        const index = event.currentTarget.dataset.index;
        const quoteId = this.chainData[index]?.quoteRecord?.Id;
        if (quoteId) {
            this.viewRecord(quoteId,'Quote');
        }
    }

    viewInvoice(event) {
        const index = event.currentTarget.dataset.index;
        const invoiceId = this.chainData[index]?.invoiceRecord?.Id;
        if (invoiceId) {
            this.viewRecord(invoiceId,'Invoice__c');
        }
    }
}