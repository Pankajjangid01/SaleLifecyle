import { LightningElement } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

import searchRecords from '@salesforce/apex/SalesLifecycleController.searchRecords';
import getLifecycleData from '@salesforce/apex/SalesLifecycleController.getLifecycleData';

const SEARCH_DEBOUNCE_MS = 300;
const MIN_SEARCH_LENGTH = 2;

export default class SalesLifecycleTracker extends NavigationMixin(LightningElement) {
    searchKey = '';
    lifecycleData;
    searchResults = [];
    selectedRecordId = null;
    selectedRecordLabel = '';
    errorMessage = '';
    isSearching = false;
    isLoadingLifecycle = false;
    showDropdown = false;
    activeResultIndex = -1;
    debounceTimeout;
    blurTimeout;
    searchRequestSequence = 0;

    disconnectedCallback() {
        window.clearTimeout(this.debounceTimeout);
        window.clearTimeout(this.blurTimeout);
        this.searchRequestSequence += 1;
    }

    get hasLifecycleData() {
        return Boolean(this.lifecycleData);
    }

    get hasSearchResults() {
        return this.searchResults.length > 0;
    }

    get showSearchEmptyState() {
        return (
            this.showDropdown &&
            !this.isSearching &&
            this.normalizedSearchKey.length >= MIN_SEARCH_LENGTH &&
            !this.hasSearchResults
        );
    }

    get normalizedSearchKey() {
        return (this.searchKey || '').trim();
    }

    get dropdownAriaExpanded() {
        return this.showDropdown ? 'true' : 'false';
    }

    get isSearchButtonDisabled() {
        return this.normalizedSearchKey.length < MIN_SEARCH_LENGTH || this.isLoadingLifecycle;
    }

    get searchBoxClass() {
        return `search-box${this.showDropdown ? ' search-box-open' : ''}`;
    }

    get stages() {
        const data = this.lifecycleData || {};
        const stageDefinitions = [
            { key: 'lead', title: 'Lead', record: data.leadRecord },
            { key: 'opportunity', title: 'Opportunity', record: data.opportunityRecord },
            { key: 'quote', title: 'Quote', record: data.quoteRecord },
            { key: 'journal', title: 'Journal', record: data.journalRecord },
            { key: 'invoice', title: 'Invoice', record: data.invoiceRecord }
        ];

        return stageDefinitions.map((stage, index) => {
            const isAvailable = Boolean(stage.record?.Id);

            return {
                ...stage,
                showConnector: index < stageDefinitions.length - 1,
                isAvailable,
                recordId: stage.record?.Id,
                recordName: stage.record?.Name,
                stageClass: `stage-shell${isAvailable ? ' stage-shell-available' : ' stage-shell-missing'}`,
                valueClass: `value${isAvailable ? ' clickable' : ' value-empty'}`,
                ariaLabel: isAvailable
                    ? `Open ${stage.title} record ${stage.record.Name}`
                    : `${stage.title} record not available`
            };
        });
    }

    handleSearchInput(event) {
        const nextValue = event.target.value;
        const previousValue = this.searchKey;

        this.searchKey = nextValue;
        this.errorMessage = '';
        this.activeResultIndex = -1;

        if (nextValue !== previousValue) {
            this.selectedRecordId = null;
            this.selectedRecordLabel = '';
            this.lifecycleData = null;
        }

        window.clearTimeout(this.debounceTimeout);

        if (this.normalizedSearchKey.length < MIN_SEARCH_LENGTH) {
            this.searchResults = [];
            this.showDropdown = false;
            this.isSearching = false;
            return;
        }

        this.showDropdown = true;
        this.debounceTimeout = window.setTimeout(() => {
            this.fetchSearchResults(this.normalizedSearchKey);
        }, SEARCH_DEBOUNCE_MS);
    }

    handleSearchFocus() {
        if (this.normalizedSearchKey.length >= MIN_SEARCH_LENGTH) {
            this.showDropdown = true;
        }
    }

    handleSearchBlur() {
        window.clearTimeout(this.blurTimeout);
        this.blurTimeout = window.setTimeout(() => {
            this.showDropdown = false;
            this.activeResultIndex = -1;
        }, 150);
    }

    handleSearchKeydown(event) {
        if (!this.hasSearchResults) {
            if (event.key === 'Escape') {
                this.showDropdown = false;
            }
            return;
        }

        if (event.key === 'ArrowDown') {
            event.preventDefault();
            this.showDropdown = true;
            this.activeResultIndex = (this.activeResultIndex + 1) % this.searchResults.length;
            this.refreshSearchResultState();
            this.focusActiveResult();
        } else if (event.key === 'ArrowUp') {
            event.preventDefault();
            this.showDropdown = true;
            this.activeResultIndex =
                this.activeResultIndex <= 0 ? this.searchResults.length - 1 : this.activeResultIndex - 1;
            this.refreshSearchResultState();
            this.focusActiveResult();
        } else if (event.key === 'Enter') {
            if (this.activeResultIndex >= 0 && this.activeResultIndex < this.searchResults.length) {
                event.preventDefault();
                this.selectSearchResult(this.searchResults[this.activeResultIndex]);
            }
        } else if (event.key === 'Escape') {
            this.showDropdown = false;
            this.activeResultIndex = -1;
        }
    }

    handleResultMouseDown(event) {
        event.preventDefault();
    }

    handleResultSelect(event) {
        const resultIndex = Number(event.currentTarget.dataset.index);
        const selectedResult = this.searchResults[resultIndex];

        if (!selectedResult) {
            return;
        }

        this.selectSearchResult(selectedResult);
    }

    async handleSearchClick() {
        if (this.normalizedSearchKey.length < MIN_SEARCH_LENGTH) {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Enter more characters',
                    message: 'Type at least 2 characters to search.',
                    variant: 'info'
                })
            );
            return;
        }

        if (!this.selectedRecordId && !this.hasSearchResults) {
            await this.fetchSearchResults(this.normalizedSearchKey);
        }

        if (this.selectedRecordId) {
            await this.fetchLifecycle();
            return;
        }

        if (this.hasSearchResults && this.activeResultIndex >= 0 && this.activeResultIndex < this.searchResults.length) {
            await this.selectSearchResult(this.searchResults[this.activeResultIndex]);
            return;
        }

        this.dispatchEvent(
            new ShowToastEvent({
                title: 'Select a record',
                message: 'Choose a record from the search results before loading the lifecycle.',
                variant: 'info'
            })
        );
    }

    async fetchSearchResults(searchTerm) {
        const requestId = ++this.searchRequestSequence;
        this.isSearching = true;

        try {
            const results = await searchRecords({ searchKey: searchTerm });

            if (requestId !== this.searchRequestSequence || searchTerm !== this.normalizedSearchKey) {
                return;
            }

            this.searchResults = (results || []).map((item, index) => ({
                ...item,
                displayLabel: `${item.recordName} (${item.objectType})`,
                ariaLabel: `${item.recordName}, ${item.objectType}`,
                isActive: index === this.activeResultIndex,
                optionClass: `search-result${index === this.activeResultIndex ? ' search-result-active' : ''}`
            }));
            this.activeResultIndex = this.searchResults.length > 0 ? 0 : -1;
            this.refreshSearchResultState();
        } catch (error) {
            if (requestId !== this.searchRequestSequence) {
                return;
            }

            this.searchResults = [];
            this.activeResultIndex = -1;
            this.handleError('Search failed', error);
        } finally {
            if (requestId === this.searchRequestSequence) {
                this.isSearching = false;
            }
        }
    }

    async fetchLifecycle() {
        if (!this.selectedRecordId) {
            return;
        }

        this.isLoadingLifecycle = true;

        try {
            this.lifecycleData = await getLifecycleData({ recordId: this.selectedRecordId });
        } catch (error) {
            this.lifecycleData = null;
            this.handleError('Lifecycle load failed', error);
        } finally {
            this.isLoadingLifecycle = false;
        }
    }

    async selectSearchResult(result) {
        this.selectedRecordId = result.recordId;
        this.selectedRecordLabel = result.displayLabel;
        this.searchKey = result.recordName;
        this.showDropdown = false;
        this.searchResults = [];
        this.activeResultIndex = -1;
        this.errorMessage = '';

        await this.fetchLifecycle();
    }

    refreshSearchResultState() {
        this.searchResults = this.searchResults.map((item, index) => ({
            ...item,
            isActive: index === this.activeResultIndex,
            optionClass: `search-result${index === this.activeResultIndex ? ' search-result-active' : ''}`
        }));
    }

    focusActiveResult() {
        window.setTimeout(() => {
            const activeButton = this.template.querySelector(`[data-index="${this.activeResultIndex}"]`);
            if (activeButton) {
                activeButton.focus();
            }
        }, 0);
    }

    navigateToRecord(event) {
        const recordId = event.currentTarget.dataset.id;
        if (!recordId) {
            return;
        }

        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId,
                actionName: 'view'
            }
        });
    }

    handleError(title, error) {
        this.errorMessage = this.reduceError(error);
        this.dispatchEvent(
            new ShowToastEvent({
                title,
                message: this.errorMessage,
                variant: 'error'
            })
        );
    }

    reduceError(error) {
        if (Array.isArray(error?.body)) {
            return error.body.map((item) => item.message).join(', ');
        }

        return error?.body?.message || error?.message || 'Something went wrong while loading data.';
    }
}