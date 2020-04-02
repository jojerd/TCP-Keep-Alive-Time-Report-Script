#TCP Keep Alive Time Report Script

1.0 - 5/15/2017 - Initial Release

1.01 - 6/28/2017 - Fixed a Foreach loop bug asking TCP KeepAliveTime values for each server when multiple servers were modified.

1.02 - 3/7/2018 - Fixed PSSnapin load errors if script was executed more than once in a single PowerShell session. Also refined how script checks for PowerShell version requirements.

As an Exchange Support Escalation Engineer at Microsoft we run into a lot of unforeseen scenarios. Recently I've been seeing an uptick in O365 migrations failing due to something that is actually pretty simple, but is often overlooked. It's even part of a blog post by my colleague David Fife titled "For Exchange 2010, 2013 and 2016 do this before calling Microsoft."

If the TCP Keep Alive Time is not set, the default is used which is 2 hours. Networking equipment is often times set to something much lower resulting in the session being terminated while the source and target both believe the session is still active. Then the migration fails due to a transient error. This can also have a negative impact on client connectivity when a load balancer is used.

David’s Blog: https://blogs.technet.microsoft.com/david231/2015/03/30/for-exchange-2010-and-2013-do-this-before-calling-microsoft/

While troubleshooting I created a script to go through and query each Exchange Server in the customer’s organization and pull a report of what their TCP Keep Alive Time value was set to. This is where the script proved to be extremely useful, especially in large environments. We noticed that not all of the TCP Keep Alive Times were set across the organization. Some even had mismatching values if they were set at all. I then added the functionality of the script to go through and add the key if it was missing and change the value if it was present. The benefit of this is that it would be the same across all Exchange servers within the local AD site. Consistency is key, if it's set to 30 minutes on the Exchange 2013 Hybrid server(s), it should be set the same on the backend Mailbox server(s).

I hard coded a site boundary within the script so if you execute it within a given AD site it will not report any Exchange servers in another AD site. It will generate a CSV report listing the names of the servers it was able to retrieve information from, as well as letting you know if the TCP KeepAliveTime registry key exists and if so what value is there. If you need to query servers in a different Active Directory site, just copy the script to an Exchange Server over to that site and execute it.

 

The Default action of the script when it presents you with the question if you'd like to change the Registry keys is "NO". You have to type "Y" or "Yes" for it to continue changing the TCP Keep Alive Time. It will then ask you how many milliseconds you would like the TCP KeepAliveTime registry key set too. By default I set it to 1.8 million milliseconds which is 30 minutes. If you decide to use the default, just hit the enter key and the default value will be set across all of the Exchange servers within the AD site. If you decide to use your own value do not use any periods or commas and just put in a round number (example 900000 which is 15 minutes). All times have to be in milliseconds.

 

Keep in mind that setting the TCP Keep Alive Time to low will increase server CPU workload, which is why the blog I referenced above recommends 15 to 30 minutes as the time it should be set too.

 

If you decide to change the TCP Keep Alive Time values, keep in mind that the changes will not take effect until you reboot the servers.

 

#Requirements

PowerShell 3.0, Exchange Management Shell, and administrative privileges on the local as well as target Exchange Servers within the local AD site.

 
