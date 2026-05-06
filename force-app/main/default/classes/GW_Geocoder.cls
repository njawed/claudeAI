public with sharing class GW_Geocoder {
/*-----------------------------------------------------------------------------------------------
* Written by Evan Callahan, copyright (c) 2010 Groundwire, 1402 3rd Avenue, Suite 1000, Seattle, WA 98101
* This program is released under the GNU General Public License. http://www.gnu.org/licenses/
* 
* interface to geocoder.us web service
* give it any address, get back latitude, longitude, and a parsed address
*
* if you do not provide a username and password for the geocoder service, the class uses the
* free version which is for non-commercial use only.  please note that you can only use the free
* version once every 15 seconds from a given IP address
*
* SAMPLE USAGE:
	// callout to geocoding service		
	GW_Geocoder gc = new GW_Geocoder('123 4th Ave N, Seattle, WA');
	gc.geocode();
	
	if (gc.locations.size() == 1) {
		// report the result
		GW_Geocoder.Location loc = gc.locations[0];
		system.debug('Latitude: ' + loc.latitude);
		system.debug('Longitude: ' + loc.longitude);
	} else if (gc.locations.size() > 1) {
		system.debug('GEOCODER FOUND MULTIPLE LOCATIONS: '); 
		system.debug(gc.locations);
	} else {
		system.debug('GEOCODING ERROR: ' + gc.error);
	}
*
* There are also triggers that automatically perform callouts for new and changed records.
* If you leave these turned on, it will try to geocode and find the district for every record.
* The trigger will also fill in the Geocoding Status and Districting Status fields.  
*
* Please note that triggers will not work on bulk import or update - the limit is 5 records 
* at a time. In addition, there is an Apex limit on async (@future) calls of 200/license/day.  
-----------------------------------------------------------------------------------------------*/

	// turn trigger processing off or on
	// set these to true if you want a trigger to geocode whenever possible
	public static final boolean geocodeAccts = true;
	public static final boolean geocodeContacts = true;
	// set these to true if you also want a trigger to get district information
	public static final boolean districtsForAccts = true;
	public static final boolean districtsForContacts = true;

	// endpoints
	final string publicEndpoint = 'rpc.geocoder.us/service/csv';
	final string authEndpoint = 'geocoder.us/member/service/csv/geocode';
    
    // optional username and password for paid service from geocoder.us
	public static final string username;	
	public static final string password;

	// subclass for geo info
	public class Location {
		public decimal latitude { get; private set; }
		public decimal longitude { get; private set; }
		public string street { get; private set; }
		public string city { get; private set; }
		public string state { get; private set; }
		public string postalcode { get; private set; }
		public string country { get; private set; }
	}
	
	// properties
	public string address { get; set; }	
	public string response { get; private set; }
	public string error { get; private set; }
	public list<location> locations { get; private set; }
	
	// need to special case the test
	final string testResp = '47.618967,-122.348993,123 4th Ave N,Seattle,WA,98109'; 
	public static boolean isTest = false;
	
	// track this so we don't call the services once we are shut out
	boolean outOfGeocoderRequests = false;

	// constructors
	public GW_Geocoder() { }
	public GW_Geocoder(string addr) {
		address = addr;
	}
	
	// call the geocoder.us service, fill results, and return the status code
	public void geocode() {

		// initialize		
		locations = new list<Location>();
		response = error = null;

		if (address != null && address.trim() != '' && !outOfGeocoderRequests) {

            string endpoint = (GW_Geocoder.username != null) ? 
            	(EncodingUtil.URLEncode(GW_Geocoder.username, 'UTF-8') + ':' + 
            		EncodingUtil.URLEncode(GW_Geocoder.password, 'UTF-8') + '@' + authEndpoint) : 
            	publicEndpoint;

			Http h = new Http();
            HttpRequest req = new HttpRequest();
            req.setEndpoint('http://' + endpoint + '?address=' + EncodingUtil.URLEncode(address, 'UTF-8'));
            req.setMethod('GET');            	
            req.setTimeout(2000);	// two seconds should be plenty, unless you are calling more than once every 15    	            
            
            try {
	        	httpResponse resp;
	            integer status;
				if (isTest) {
					response = testResp;
					status = 200;					
				} else {					
		            resp = h.send(req);
					response = resp.getBody();
					status = resp.getStatusCode();
				}								
				if (status == 200) {
					if (response != null) {
						for (string addr : response.split('\n')) {
							string[] parsed = addr.split(',');
							if (parsed.size() == 6) {
								
								// add a new location to the list
								GW_Geocoder.Location loc = new GW_Geocoder.Location(); 
								loc.latitude = decimal.valueOf(parsed[0]);
								loc.longitude = decimal.valueOf(parsed[1]);
								loc.street = parsed[2];
								loc.city = parsed[3];
								loc.state = parsed[4];
								loc.postalCode = parsed[5];
								locations.add(loc);
							}
						}
						if (locations.isEmpty())
							error = 'Response from geocoding service: ' + response;						
					} else {
						error = 'No response from geocoding service.';
					}
				} else {
					error = 'Unexpected response from geocoding service (STATUS ' + string.valueOf(status) + '): \n' + response;
				}
				
            } catch( System.Exception e) {
            	if (e.getMessage().startsWith('Unauthorized endpoint')) {
					error = 'Before using the geocoder.us service, an administrator must go to Setup => Security => Remote Site Settings ' +
						'and add the following endpoint:  http://' + ((GW_Geocoder.username != null) ? authEndpoint : publicEndpoint);
            	} else {
					error = 'Error communicating with geocoding service: ' + e.getMessage();
					outOfGeocoderRequests = (error.contains('Read timed out'));
            	}
			} finally {
				if (error != null)
					system.debug(loggingLevel.ERROR, error);
			}
		}
	}

    // geocode and get districts for a list of accounts
    // call from after insert/update trigger
    @future (callout=true)
    public static void updateAcctGeo( list<id> acctids, list<string> addr ) { 
    	
	    GW_Geocoder gc = new GW_Geocoder();
	    list<account> alist = new list<account>();

		// we can only call out 10 times
		integer maxrecs = GW_Geocoder.districtsForAccts ? 10 : 5;
    	integer cnt = (acctids.size() > maxrecs) ? maxrecs : acctids.size();

    	for (integer i=0; i < cnt; i++) {
    		// create an account record to update
    		account a = new account( 
    			id = acctids[i],
    			geocoding_status__c = '[' + system.today().format() + ']'
    		);
    		
    		// geocode
			gc.address = addr[i];
			gc.geocode();
			
			if (gc.error != null) {
				a.geocoding_status__c += ' ' + gc.error;
			} else if (gc.locations.size() != 1) {
				a.geocoding_status__c += ' Found multiple addresses.';
			} else {  
			    a.latitude__c = gc.locations[0].latitude;
			    a.longitude__c = gc.locations[0].longitude;
				a.geocoding_status__c += ' Success';			
			    
			 	// also get the district
			 	a.districting_status__c = '[' + system.today().format() + ']';
				if (isTest || (GW_Geocoder.districtsForAccts && gc.locations[0].latitude != null)) {
					GW_MobileCommons mc = new GW_MobileCommons();
			        mc.latitude = gc.locations[0].latitude;
			        mc.longitude = gc.locations[0].longitude;
			        mc.getDistricts();
					if (mc.error == null) {		
						// save to the account
						a.Cong_District__c = mc.congress;
						a.State_Senate__c = mc.stateSenate;
						a.Voter_Leg_District__c = mc.stateHouse;
						a.districting_status__c += ' Success';							
					} else {
						a.districting_status__c += ' ' + mc.error;							
					}				
				}
			}
			// add this account to the update list
			alist.add(a);
    	}
        if (!alist.isEmpty()) update alist;
    }
    
    // geocode and get districts for a list of contacts
    // call from after insert/update trigger
    @future (callout=true)
    public static void updateContactGeo( list<id> conids, list<string> addr ) { 
    	
	    GW_Geocoder gc = new GW_Geocoder();
	    list<contact> clist = new list<contact>();

		// we can only call out 10 times
		integer maxrecs = GW_Geocoder.districtsForContacts ? 10 : 5;
    	integer cnt = (conids.size() > maxrecs) ? maxrecs : conids.size();

    	for (integer i=0; i < cnt; i++) {
    		contact c = new contact( 
    			id = conids[i],
    			geocoding_status__c = '[' + system.today().format() + ']'
    		);
    		
    		// geocode
			gc.address = addr[i];
			gc.geocode();
			
			if (gc.error != null) {
				c.geocoding_status__c += gc.error;
			} else if (gc.locations.size() != 1) {
				c.geocoding_status__c += ' Found multiple addresses. ';
			} else {  
			    c.latitude__c = gc.locations[0].latitude;
			    c.longitude__c = gc.locations[0].longitude;
				c.geocoding_status__c += ' Success';			
			    
			 	// also get the district
			 	c.districting_status__c = '[' + system.today().format() + ']';
				if (isTest || (GW_Geocoder.districtsForAccts && gc.locations[0].latitude != null)) {
					GW_MobileCommons mc = new GW_MobileCommons();
			        mc.latitude = gc.locations[0].latitude;
			        mc.longitude = gc.locations[0].longitude;
			        mc.getDistricts();
					if (mc.error == null) {		
						// save to the account
						c.Cong_District__c = mc.congress;
						c.State_Senate__c = mc.stateSenate;
						c.Voter_Leg_District__c = mc.stateHouse;
						c.districting_status__c += ' Success';							
					} else {
						c.districting_status__c += ' ' + mc.error;							
					}				
				}
			}
			// add this contact to the update list
			clist.add(c);
    	}
        if (!clist.isEmpty()) update clist;
    }

	public static testMethod void testGeocoder() {
		GW_Geocoder.isTest = true;
		GW_Geocoder gc = new GW_Geocoder('123 4th Ave, Seattle, WA');
		gc.geocode();
		system.assertEquals(47.618967, gc.locations[0].latitude);
	}

	public static testMethod void testGeocodingTrigger() {
		GW_Geocoder.isTest = true;
		GW_MobileCommons.isTest = true;
		contact c1 = new contact(lastname='Test', otherstreet = '123 4th Ave', otherCity = 'Seattle', otherState = 'WA', otherpostalcode= '98101'  );
		contact c2 = new contact(lastname='Test', mailingstreet = '123 4th Ave', mailingCity = 'Seattle', mailingState = 'WA', mailingpostalcode= '98101' );
		account a = new account(name ='Test', billingstreet = '123 4th Ave', billingCity = 'Seattle', billingState = 'WA', billingpostalcode= '98101'  );
		test.startTest();
		insert a;
		insert c1;
		insert c2;
		test.stopTest();
		system.assertEquals(47.618967, [select latitude__c from account where id = : a.id].latitude__c);
		system.assertEquals(47.618967, [select latitude__c from contact where id = : c1.id].latitude__c);
		system.assertEquals(47.618967, [select latitude__c from contact where id = : c2.id].latitude__c);
		system.assertEquals(2, [select Cong_District__c from account where id = : a.id].Cong_District__c);
		system.assertEquals(2, [select Cong_District__c from contact where id = : c1.id].Cong_District__c);
		system.assertEquals(2, [select Cong_District__c from contact where id = : c2.id].Cong_District__c);		
	}
}