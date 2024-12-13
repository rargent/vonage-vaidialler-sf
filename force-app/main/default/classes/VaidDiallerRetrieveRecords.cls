public  with sharing class VaidDiallerRetrieveRecords {
    @InvocableMethod(label='Update Dial Entries' description='Updates Dial Entries based on criteria')
    public static List<UpdateResult> updateDialEntries(List<UpdateRequest> requests) {
        List<UpdateResult> results = new List<UpdateResult>();
        System.debug('Starting updateDialEntries:::');

        UpdateRequest request = requests[0];
        

        System.debug('Request::: ' + request);

        try {
            String queryString = constructQueryString(request);
            System.debug('Query String::: ' + queryString);
            List<VAID_Dial_Entry__c> entriesToUpdate = Database.query(queryString);
            System.debug('Entries to Update::: ' + entriesToUpdate.size());

            for (VAID_Dial_Entry__c entry : entriesToUpdate) {
                entry.VAID_Dial_Status__c = 'Retrieved';
            }
            
            if (!entriesToUpdate.isEmpty()) {
                Database.SaveResult[] saveResults = Database.update(entriesToUpdate, false);
                Integer updatedCount = 0;
                for (Database.SaveResult sr : saveResults) {
                    if (sr.isSuccess()) {
                        updatedCount++;
                    }
                }
                results.add(new UpdateResult(updatedCount, 'Records updated successfully'));
            } else {
                results.add(new UpdateResult(0, 'No records found to update'));
            }

        } catch (Exception e) {
            System.debug('Exception::: ' + e.getMessage());
            results.add(new UpdateResult(0, e.getMessage()));
            // return results;
            
        }
        return results;
    }

    private static String constructQueryString(UpdateRequest request) {
        Id dialListId = request.dialListId;
        Boolean priorityFilterEnabled = request.priorityFilterEnabled;
        Boolean phoneNumberFilterEnabled = request.phoneNumberFilterEnabled;
        Boolean recoveryTypeFilterEnabled = request.recoveryTypeFilterEnabled;
        String prioritisationSortField = request.prioritisationSortField;
        String prioritisationSortOrder = request.prioritisationSortOrder;
        String priorityFilter = request.priorityFilter;
        String phoneNumberFilter = request.phoneNumberFilter;
        String recoveryTypeFilter = request.recoveryTypeFilter;

        String queryString = 'SELECT Id FROM VAID_Dial_Entry__c WHERE VAID_Is_Dialable__c = true AND VAID_Dial_List__c = \'' + dialListId + '\'';
        
        if (priorityFilterEnabled && priorityFilter != null) {
            queryString += ' AND VAID_Recovery_Flow__r.Priority__c = ' + priorityFilter;
        }
        if (phoneNumberFilterEnabled && phoneNumberFilter != null) {
            queryString += ' AND VAID_Phone_Number_Type__c = ' + phoneNumberFilter;
        }
        if (recoveryTypeFilterEnabled && recoveryTypeFilter != null) {
            queryString += ' AND Recovery_Type__c = ' + recoveryTypeFilter;
        }

        // Add Order By Clauses
        if ( prioritisationSortField != null & prioritisationSortOrder != null) {
            if (prioritisationSortOrder == 'ASC') {
                queryString += ' ORDER BY ' + prioritisationSortField +  ' ASC';
            } else if (prioritisationSortOrder == 'DESC') {
                queryString += ' ORDER BY ' + prioritisationSortField +  ' DESC';
            } else {
                queryString += ' ORDER BY VAID_Prioritization_Score__c DESC';
            }
        }

        queryString += ', VAID_Phone_Number_Type__c,VAID_Next_Contact_Time__c';
    
        // Add Limit Clause
        queryString += ' LIMIT 3';

        return queryString;
    }    

    public class UpdateRequest {
        @InvocableVariable(required=true label='Dial List Id')
        public String dialListId;
        
        @InvocableVariable(required=true label='Priority Filter Enabled')
        public Boolean priorityFilterEnabled;
        
        @InvocableVariable(required=false label='Priority Filter')
        public String priorityFilter;
        
        @InvocableVariable(required=true label='Phone Number Filter Enabled')
        public Boolean phoneNumberFilterEnabled;
        
        @InvocableVariable(required=false label='Phone Number Filter')
        public String phoneNumberFilter;
        
        @InvocableVariable(required=true label='Recovery Type Filter Enabled')
        public Boolean recoveryTypeFilterEnabled;
        
        @InvocableVariable(required=false label='Recovery Type Filter')
        public String recoveryTypeFilter;
        
        @InvocableVariable(required=true label='Prioritisation Sort Field' description='Pass in API Name of the field to sort by from the VAID_Dial_Entry__c object. Default is VAID_Prioritization_Score__c')
        public String prioritisationSortField;
        
        @InvocableVariable(required=true label='Prioritisation Sort Order' description='Valid Options are ASC or DESC')
        public String prioritisationSortOrder;
    }

    public class UpdateResult {
        @InvocableVariable(description='Number of records updated')
        public Integer updatedCount;
        
        @InvocableVariable(description='Result message')
        public String message;
        
        public UpdateResult(Integer updatedCount, String message) {
            this.updatedCount = updatedCount;
            this.message = message;
        }
    }

}