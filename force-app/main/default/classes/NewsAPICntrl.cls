/**
 * @description NewsAPICntrl class is controller class for the news lighting component. 
 * @method1 : fetchNewsSources : Fetch news source from custom metadata type store in the salesforce org.
 * @method2 : fetchCountries :  Fetch countries names from custom metadata type store in the salesforce org.
 * @method3 : getNews : This method gets the top headline news from NewsAPI 
 * @method4 : getNewsByCountry : This method get the news based on country input provided by end users
 * @method5 : getNewsByCategory : Method used to get the news based on categories (like: Sport, Health, Business,etc) for perticular country
 * @method6 : findNews : Method finds the news article base on the user input 
 * @method7 : doCallout : Method used to make the callout to NEWS API REST API.
 */
public without sharing class NewsAPICntrl {
    
    /**
     * @description fetchNewsSources method gets all the new source names from custom metadata type
     * @return List<string>
     */
    @AuraEnabled
    public static Map<String, News_Source__mdt> fetchNewsSources(){
        try{
            //return list of new source names
            return News_Source__mdt.getAll();
        } 
        catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    /**
     * @description fetch countries method get the countries from custom metadata type
     * @return Map<String,Country__mdt>
     */
    @AuraEnabled
    public static Map<String,Country__mdt> fetchCountries(){
        //return list of countries
        return Country__mdt.getAll(); 
    }
    
    /**
     * @description getNews method gets the news from NewsAPI.org
     * @param source_name
     * @param isDomainSource
     * @return JsonNewWrapper
     */
    @AuraEnabled
    public static NewsJSONParser getNews(String sourceName, Boolean isDomainSource){

        //get the news source custom metadata map
        Map<String,News_Source__mdt> newsSourceMap =  NewsSourceCls.getNewsSource();
       
        String sourceNews;
        String calloutURL;

        if( sourceName <> null && sourceName !='' ){
            sourceNews = newsSourceMap.get(String.escapeSingleQuotes(sourceName)).Source_API_name__c;   
        }
        if(isDomainSource){
            calloutURL='v2/everything?domains='+sourceNews;
        }
        else
        {
            calloutURL = 'v2/top-headlines?sources='+sourceNews;
        }
        
        //send the request to search 
        NewsJSONParser response = doCallout(calloutURL);
        
        //return the response
        return response;
    }
    /**
     * @description getNewsByCountry method gets the news based on the country
     * @param countryName
     * @return NewsJSONParser
     */
     @AuraEnabled
    public static NewsJSONParser getNewsByCountry(string countryName){

        //get the country custom metadata type map 
        Map<String,Country__mdt> countryMap = NewsSourceCls.getcountryMap();
      
        string countryID;
        String calloutURL;

        if(countryName <> null && countryName !=''){
            countryID = countryMap.get(String.escapeSingleQuotes(countryName)).Country_code__c;      
        }

        calloutURL = 'v2/top-headlines'+ '?country=' + countryID ;

        //send the request to search 
        NewsJSONParser response = doCallout(calloutURL);

        //return the response
        return response;
    }
    
    /**
     * @description getNewsByCategory method gets the news based on category
     * @param countryNameOrSource
     * @param categoryStr
     * @return 
     */
     @AuraEnabled
    public static NewsJSONParser getNewsByCategory(String countryNameOrSource, String categoryStr){

        //get the country custom metadata type map 
        Map<string,Country__mdt> countryMap = NewsSourceCls.getcountryMap();

        //get the news source custom metadata map
        Map<string,News_Source__mdt> newsSourceMap =  NewsSourceCls.getNewsSource();

        string countryID='';
        string sourceName='';

        if(countryNameOrSource<>null && countryNameOrSource!=''){
            if(countryMap.containsKey(countryNameOrSource)){
                //get the country id or code (like us,in,ca)
                countryID = countryMap.get(String.escapeSingleQuotes(countryNameOrSource)).Country_code__c;  
            }
            else{
                //get the source api name
                sourceName = newsSourceMap.get(String.escapeSingleQuotes(countryNameOrSource)).Source_API_name__c;
            }   
        }//if block ends here
        
        String categoryBasedOnCountryOrSource = '';
        String callOutURL = '';

        //if country id is not blank
        if(countryID!=''){
            categoryBasedOnCountryOrSource = '?country=' + countryID ;
        }
        else{
            categoryBasedOnCountryOrSource = '?sources=' + sourceName ;
        }
        callOutURL = 'v2/top-headlines' + categoryBasedOnCountryOrSource + '&category=' + categoryStr;

        //send the request to search 
        NewsJSONParser response = doCallout(callOutURL);

        //return the response
        return response;
    }
    
    /**
     * @description findNews method search the article/news : user send the search string from user interface (lightning component)
     * @param searchString
     * @return NewsJSONParser
     */
    @AuraEnabled
    public static NewsJSONParser findNews(string searchString){
        
        //Get today's day      
        Integer day = system.today().day()-2;

        //Format the date
        String formDate = string.valueOf(system.today().year()+'-0'+system.today().month()+'-0'+day);

        //Make the search url
        string searchURL='v2/everything?q='+searchString+'&language=en&from='+formDate+'&sortBy=publishedAt';
        
        //send the request to search 
        NewsJSONParser response = doCallout(searchURL);

        //return the response
        return response;
    }

    /**
     * @description doCallout is HTTP GET method to call the NewsAPI to get the news details.
     * @param endpointURL
     * @return NewsJSONParser
     */
    public static NewsJSONParser doCallout(String endpointURL){

        try{

            //HTTP GET request to call the NewsAPI
            HttpRequest req = new HttpRequest();

            //Set the method type GET
            req.setMethod('GET');

            //Set the base URL from Salesforce named crdentials (NewsAPI) and append the url to fetch the information
            req.setEndpoint('callout:NewsAPI'+'/'+endpointURL);

            //Add the API Key in the header from named credential (NewsAPI) using merge field
            req.setHeader('X-Api-Key', '{!$Credential.Password}');

            req.setHeader('Accept','application/json');

            //Send the request
            HttpResponse res = new Http().send(req);

            //Parse the reponse returned from api, using NewsJSONParser Apex class
            NewsJSONParser parserObj = NewsJSONParser.parse(res.getBody()); 
            //return the parsed object.
            return parserObj;
        }
        catch(Exception e){
            system.debug('Exception has occured! ' + e.getMessage());
            return null;
        }
    }
    
}