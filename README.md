Nomnom! Give me all yer metadaters!


Routes:
 - / - landing page
   /single - download & parse single URI
   /crawl - crawl, downloading & parsing from a root URI

Example:
```
$ curl -X POST -d "key=jcran&uri=http://intrigue.io&depth=4" http://nomnom-api.intrigue.io/crawl

```  
