public class PossibleConditionExt {
	public List<PossibleCondition__c> PossibleConditions { get; set; }
	public Contact userContact { get; set; }
	public List<String> SelectedConditions { get; set; }
	public List<Specialty__c> Specialties { get; set; }
	public List<SelectOption> options = new List<SelectOption>();
	public Boolean isButtonVisible {get; set;}
	public String selectedDoctor = null;
	public PossibleConditionExt() {
		isButtonVisible = false;
		String userId = UserInfo.getUserId();
		PossibleConditions = [
			SELECT Selected__c, Condition__c, Probability__c, Condition__r.CommonName__c
			FROM PossibleCondition__c
			WHERE Appointment__c = NULL
		];

	}

	public List<SelectOption> getItems() {
		return options;
	}

	public String getSelectedDoctor() {
		return selectedDoctor;
	}
	public void setSelectedDoctor(String selectedDoctor) {
		this.selectedDoctor = selectedDoctor;
	}

	public void submitForDoctors() {
		try {
				SelectedConditions = new List<String>();
				// collect condition ids
				List<Id> idList = new List<Id>();

				for (PossibleCondition__c pCond :PossibleConditions) {
					if(pCond.Selected__c == true) {
						idList.add(pCond.Condition__c);
					}
				}
				Specialties = [
					SELECT Doctor__r.Name, Condition__r.CommonName__c
					FROM Specialty__c
					WHERE Condition__c IN :idList
				];
				Map<Id, String> condNamesMap = new Map<Id, String>();
				for (Condition__c cc :[SELECT Id, CommonName__c FROM Condition__c]) {
					if(!condNamesMap.containsKey(cc.Id)) {
						condNamesMap.put(cc.Id, cc.CommonName__c);
						}
				}
				Map<String, List<String>> doctorListOfConditions = new Map<String, List<String>>();
				for(Specialty__c sp :Specialties) {
					String docName = sp.Doctor__r.Name;
					String condName = condNamesMap.get(sp.Condition__c);

					if(doctorListOfConditions.containsKey(docName)) {
						doctorListOfConditions.get(docName).add(condName);
					} else {
						doctorListOfConditions.put(docName, new List<String>{condName});
					}
				}
				for(String key : doctorListOfConditions.keySet()) {
					String value = key + doctorListOfConditions.get(key);
					options.add(new SelectOption(key, value));
				}
				isButtonVisible = true;
		} catch (Exception ex) {
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, ex.getMessage()));
		}
	}

	public PageReference goToAppointmentPage()
	{
		try{
			String doctorName = getSelectedDoctor().split('\\(')[0].trim();
			Id docId = [SELECT Id FROM Doctor__c WHERE Name LIKE: doctorName].get(0).Id; 
			Id patId = [SELECT Id FROM Contact WHERE Id IN (SELECT ContactId FROM User WHERE Id = :UserInfo.getUserId())][0].Id;
			PageReference pageRef = new PageReference('/apex/AppointmentCalendar?docId=' + docId +'&patId=' +patId);
        	return pageRef;
		}
		catch(Exception ex){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Please Select a Condition First '  + ex.getMessage()));	
			return null;	
		}
	}
}