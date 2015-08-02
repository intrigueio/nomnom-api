Nomnom! Give me all yer metadaters!

Dependencies:
 - jruby
 - redis

API Routes:
 - / - landing page
 - /single - download & parse single URI
 - /crawl - crawl, downloading & parsing from a root URI

Example:
```
$ curl -X POST -d "key=jcran&uri=http://intrigue.io&depth=4" http://nomnom-api.intrigue.io/crawl
```  

CLI Usage:
````
jcran intrigue-nomnom jruby-1.7.19@intrigue-nomnom: [20150730]$ bundle exec jruby -J-Xmx1024m ./cli.rb https://www.whitehouse.gov 3
[ ] Nomnom initialized!
[ ] crawling: https://www.whitehouse.gov
[ ] Parsing text from https://www.whitehouse.gov/
[ ] Parsing text from https://www.whitehouse.gov/live
[ ] Parsing text from https://www.whitehouse.gov/email-updates
[ ] Parsing text from https://www.whitehouse.gov/
[ ] Parsing text from https://www.whitehouse.gov/contact
[ ] Parsing text from https://www.whitehouse.gov/briefing-room/weekly-address
[ ] Parsing text from https://www.whitehouse.gov/briefing-room/speeches-and-remarks
[ ] Parsing text from https://www.whitehouse.gov/briefing-room/press-briefings
[ ] Parsing text from https://www.whitehouse.gov/briefing-room/presidential-actions
[ ] Parsing text from https://www.whitehouse.gov/briefing-room/statements-and-releases
[ ] Parsing text from https://www.whitehouse.gov/briefing-room/legislation
[ ] Parsing text from https://www.whitehouse.gov/briefing-room/nominations-and-appointments
[ ] Parsing text from https://www.whitehouse.gov/briefing-room/disclosures
[ ] Parsing text from https://www.whitehouse.gov/raise-the-wage
[ ] Parsing text from https://www.whitehouse.gov/issues/disabilities
[ ] Parsing text from https://www.whitehouse.gov/issues/defense
[ ] Parsing text from https://www.whitehouse.gov/issues/homeland-security
[ ] Parsing text from https://www.whitehouse.gov/issues/service
[ ] Parsing text from https://www.whitehouse.gov/issues/seniors-and-social-security
[ ] Parsing text from https://www.whitehouse.gov/issues/taxes
[ ] Parsing text from https://www.whitehouse.gov/issues/technology
[ ] Parsing text from https://www.whitehouse.gov/issues/economy/trade
[ ] Parsing text from https://www.whitehouse.gov/administration/vice-president-biden
[ ] Parsing text from https://www.whitehouse.gov/administration/president-obama
[ ] Parsing text from https://www.whitehouse.gov/administration/first-lady-michelle-obama
[ ] Parsing text from https://www.whitehouse.gov/administration/jill-biden
[ ] Parsing text from https://www.whitehouse.gov/administration/cabinet
[ ] Parsing text from https://www.whitehouse.gov/administration/eop
[ ] Parsing text from https://www.whitehouse.gov/administration/senior-leadership
[ ] Parsing text from https://www.whitehouse.gov/administration/other-advisory-boards
[ ] Parsing text from https://www.whitehouse.gov/we-the-geeks
[ ] Parsing text from https://www.whitehouse.gov/developers
[ ] Parsing text from https://www.whitehouse.gov/tools
[ ] Parsing text from https://www.whitehouse.gov/participate/tours-and-events
[+] Creating entity: PhoneNumber, {:name=>"202-456-7041", :source=>"https://www.whitehouse.gov/participate/tours-and-events"}
[ ] Parsing text from https://www.whitehouse.gov/eastereggroll
[ ] Parsing text from https://www.whitehouse.gov/participate/internships
[ ] Parsing text from https://www.whitehouse.gov/innovationfellows
[ ] Parsing text from https://www.whitehouse.gov/1600/Presidents
[ ] Parsing text from https://www.whitehouse.gov/1600/first-ladies
[ ] Parsing text from https://www.whitehouse.gov/1600/vp-residence
[ ] Parsing text from https://www.whitehouse.gov/1600/eeob
[ ] Parsing text from https://www.whitehouse.gov/1600/camp-david
[ ] Parsing text from https://www.whitehouse.gov/1600/air-force-one
...
````
