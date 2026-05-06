/*
 * Author Nasir Jawed
 */

public Class ApexCallouts{

    public HttpRequest buildWebServiceRequest(String url){    
        //Build HTTP Request object
        HttpRequest req = new HttpRequest();
        req.setEndpoint(url);
        req.setMethod('GET');
        return req;
    }
    
    public HttpResponse invokeWebService(Http h, HttpRequest req){        
        //Invoke Web Service
        HttpResponse res = h.send(req);
        return res;
    }
    
    public String handleWebServiceResponse(HttpResponse res){  
       //Parse and apply logic to the res message
        String resp = res.getBody();
        return resp;
    }
    
    public static testMethod void testHttpCallout() {
        ApexCallouts ac = new ApexCallouts();
        Http h = new Http();
        HttpRequest req = ac.buildWebServiceRequest('test url');
        HttpResponse res = new HttpResponse();  
        
        ac.handleWebServiceResponse(res);
        ac.invokeWebService(h,req);
    }   


}