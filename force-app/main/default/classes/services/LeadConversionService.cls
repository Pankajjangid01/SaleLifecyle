public with sharing class LeadConversionService {

    private static final Integer BATCH_SIZE = 20;

    public static void convertLeads(List<Lead> leads) {

        LeadStatus convertedStatus = [
            SELECT MasterLabel
            FROM LeadStatus
            WHERE IsConverted = true
            LIMIT 1
        ];

        for (Integer i = 0; i < leads.size(); i += BATCH_SIZE) {

            List<Database.LeadConvert> chunk =
                new List<Database.LeadConvert>();

            Integer endIndex = Math.min(i + BATCH_SIZE, leads.size());

            for (Integer j = i; j < endIndex; j++) {

                Database.LeadConvert lc =
                    new Database.LeadConvert();

                lc.setLeadId(leads[j].Id);
                lc.setConvertedStatus(
                    convertedStatus.MasterLabel
                );

                lc.setDoNotCreateOpportunity(false);

                chunk.add(lc);
            }

            Database.convertLead(chunk, false);
        }
    }
}