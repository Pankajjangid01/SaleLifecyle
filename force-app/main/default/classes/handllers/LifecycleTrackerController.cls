public with sharing class LifecycleTrackerController {
    public class SearchResult {
        @AuraEnabled public Lead lead { get; set; }
        @AuraEnabled public Opportunity opportunity { get; set; }
        @AuraEnabled public Quote quoteRecord { get; set; }
        @AuraEnabled public Invoice__c invoiceRecord { get; set; }
        
        public SearchResult() {
            this.lead = null;
            this.opportunity = null;
            this.quoteRecord = null;
            this.invoiceRecord = null;
        }
    }

    @AuraEnabled
    public static List<SearchResult> getChain(String searchId) {
        try {
            if (String.isBlank(searchId)) {
                throw new AuraHandledException('Search ID cannot be blank.');
            }

            if (searchId.length() < 3) {
                throw new AuraHandledException('Search ID must be at least 3 characters long.');
            }

            String likePattern = '%' + searchId + '%';
            List<SearchResult> results = new List<SearchResult>();
            Set<Id> processedOppIds = new Set<Id>();
            Set<Id> processedInvoiceIds = new Set<Id>();

            // 1) Search leads
            List<Lead> leadList = [
                SELECT Id, Name, Company, Status, Email, Phone, ConvertedOpportunityId
                FROM Lead
                WHERE Name LIKE :likePattern OR Company LIKE :likePattern
                LIMIT 10
            ];

            Map<Id, Lead> leadMap = new Map<Id, Lead>(leadList);

            // 2) Get opportunities from leads
            Set<Id> oppIdsFromLeads = new Set<Id>();
            for (Lead l : leadList) {
                if (l.ConvertedOpportunityId != null) {
                    oppIdsFromLeads.add(l.ConvertedOpportunityId);
                }
            }

            // 3) Search opportunities directly
            List<Opportunity> oppList = [
                SELECT Id, Name, StageName, CloseDate, Amount, AccountId, Account.Name
                FROM Opportunity
                WHERE Name LIKE :likePattern
                LIMIT 10
            ];

            Set<Id> allOppIds = new Set<Id>();
            for (Opportunity o : oppList) {
                allOppIds.add(o.Id);
            }
            allOppIds.addAll(oppIdsFromLeads);

            Map<Id, Opportunity> oppMap = new Map<Id, Opportunity>(oppList);
            if (!oppIdsFromLeads.isEmpty()) {
                List<Opportunity> oppFromLeads = [
                    SELECT Id, Name, StageName, CloseDate, Amount, AccountId, Account.Name
                    FROM Opportunity
                    WHERE Id IN :oppIdsFromLeads
                ];
                oppMap.putAll(new Map<Id, Opportunity>(oppFromLeads));
            }

            // 4) Get quotes and invoices for all opportunities
            Map<Id, Quote> quoteByOpp = new Map<Id, Quote>();
            Map<Id, Invoice__c> invoiceByOpp = new Map<Id, Invoice__c>();

            if (!allOppIds.isEmpty()) {
                List<Quote> quoteList = [
                    SELECT Id, Name, QuoteNumber, TotalPrice, OpportunityId
                    FROM Quote
                    WHERE OpportunityId IN :allOppIds
                    ORDER BY CreatedDate DESC
                ];
                for (Quote q : quoteList) {
                    if (!quoteByOpp.containsKey(q.OpportunityId)) {
                        quoteByOpp.put(q.OpportunityId, q);
                    }
                }

                List<Invoice__c> invList = [
                    SELECT Id, Name, Amount__c, Due_Date__c, Account__c, Account__r.Name, Opportunity__c
                    FROM Invoice__c
                    WHERE Opportunity__c IN :allOppIds
                    ORDER BY CreatedDate DESC
                ];
                for (Invoice__c inv : invList) {
                    if (!invoiceByOpp.containsKey(inv.Opportunity__c)) {
                        invoiceByOpp.put(inv.Opportunity__c, inv);
                    }
                }
            }

            // 5) Search invoices directly
            List<Invoice__c> invoiceList = [
                SELECT Id, Name, Amount__c, Due_Date__c, Account__c, Account__r.Name, Opportunity__c
                FROM Invoice__c
                WHERE Name LIKE :likePattern
                ORDER BY CreatedDate DESC
                LIMIT 10
            ];

            Set<Id> invoiceOppIds = new Set<Id>();
            for (Invoice__c inv : invoiceList) {
                if (inv.Opportunity__c != null) {
                    invoiceOppIds.add(inv.Opportunity__c);
                }
            }

            // Get opportunities for invoices
            if (!invoiceOppIds.isEmpty()) {
                for (Opportunity o : [SELECT Id, Name, StageName, CloseDate, Amount, AccountId, Account.Name FROM Opportunity WHERE Id IN :invoiceOppIds]) {
                    if (!oppMap.containsKey(o.Id)) {
                        oppMap.put(o.Id, o);
                        allOppIds.add(o.Id);
                    }
                }
            }

            // 6) Build results from leads
            for (Lead lead : leadList) {
                SearchResult sr = new SearchResult();
                sr.lead = lead;
                if (lead.ConvertedOpportunityId != null) {
                    sr.opportunity = oppMap.get(lead.ConvertedOpportunityId);
                    if (sr.opportunity != null) {
                        sr.quoteRecord = quoteByOpp.get(lead.ConvertedOpportunityId);
                        sr.invoiceRecord = invoiceByOpp.get(lead.ConvertedOpportunityId);
                        processedOppIds.add(lead.ConvertedOpportunityId);
                    }
                }
                results.add(sr);
            }

            // 7) Build results from opportunities (excluding already-processed)
            for (Opportunity opp : oppList) {
                if (processedOppIds.contains(opp.Id)) continue;
                SearchResult sr = new SearchResult();
                sr.opportunity = opp;
                sr.quoteRecord = quoteByOpp.get(opp.Id);
                sr.invoiceRecord = invoiceByOpp.get(opp.Id);
                results.add(sr);
                processedOppIds.add(opp.Id);
            }

            // 8) Build results from invoices (excluding already-processed)
            for (Invoice__c inv : invoiceList) {
                if (processedInvoiceIds.contains(inv.Id)) continue;
                SearchResult sr = new SearchResult();
                sr.invoiceRecord = inv;
                if (inv.Opportunity__c != null) {
                    sr.opportunity = oppMap.get(inv.Opportunity__c);
                    if (sr.opportunity != null) {
                        sr.quoteRecord = quoteByOpp.get(inv.Opportunity__c);
                    }
                }
                results.add(sr);
                processedInvoiceIds.add(inv.Id);
            }

            if (results.isEmpty()) {
                throw new AuraHandledException('No matching Lead, Opportunity, or Invoice found for the search term.');
            }

            return results;
        } catch (AuraHandledException ahe) {
            throw ahe;
        } catch (Exception e) {
            System.debug('LifecycleTrackerController.getChain error: ' + e.getMessage() + '\n' + e.getStackTraceString());
            throw new AuraHandledException('Server error: ' + e.getMessage());
        }
    }
}