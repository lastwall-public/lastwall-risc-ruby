# ![Lastwall Logo](logo.png) Lastwall RISC Ruby Module

Lastwall risk-based authentication module for Ruby

## Overview

The Lastwall RISC platform allows your website to perform risk-based spot checks on a user's browsing session and verify his identity. You may perform RISC spot checks at any point during a user's browsing session. These spot checks will occur automatically and invisibly to your end users.

This document provides pseudo-code to describe our Ruby integration module.

Before reading this document, please read our general [integratrion documentation](Integration.md).

For bare-bones API documentation, please [click here](API.md).


## Initialization

First, download Risc.rb and RiscResponse.rb from our github repository `lastwall-risc-ruby`. Initialize like this:

```
token = "LWK150D380544E303C57E57036F628DA2195FDFEE3DE404F4AA4D7D5397D5D35010"   # replace with your API token
secret = "2B60355A24C907761DA3B09C7B8794C7F9B8BE1D70D2488C36CAF85E37DB2C"       # replace with your API secret
require "Risc.rb";
risc = Risc.new(token, secret);
```


## Verify API Key

Not really necessary, but good for peace of mind.

```
result = risc.Verify()
if (result.OK())
	puts "Verified!"
else
	puts "Error: " + result.Error()
end
```


## Get URL for RISC Script

Our javascript requires both a public API token and a user ID in the URL. The specific format is `https://risc.lastwall.com/risc/script/API_TOKEN/USER_ID`. The username is typically available on the client side before creating a RISC snapshot. To construct the URL, you can use our convenience function within the client-side javascript like this:

```
script_url = risc.GetScriptUrl
// script_url looks like this: "https://risc.lastwall.com/risc/script/API_TOKEN/USER_ID"
```

In Javascript, load the script like shown:
```
loadRiscScript(script_url);
```

NOTE: when you append the username to the URL, don't forget to URI-encode it!


## Decrypt Snapshot

An encrypted snapshot is obtained by the client browser by running the asynchronous RISC javascript. This encrypted blob (which is just a string) must be passed to your server somehow (typically via hidden form submission). Only your server can decrypt it, using your API secret.

```
// encr_snapshot is the Lastwall encrypted snapshot
snapshot = risc.DecryptSnapshot(encr_snapshot);
puts 'RISC session ended with score ' + snapshot["score"] + ', status: ' + snapshot["status"];
// TODO: error handling
```


## Validate Snapshot (optional, recommended)

The `validate` API call will compare your decrypted RISC snapshot result against the one saved in the Lastwall database. They should be identical. If they aren't, the only explanation is that a hacker has decrypted the result client-side, modified it, then re-encrypted it before sending it to your server. This is only possible if he has access to your API secret, or the computing power of an array of super computers stretching from here to Saturn.

```
// Decrypt the snapshot first, then validate it by API call to Lastwall
snapshot = risc.DecryptSnapshot(encr_snapshot);
result = risc.ValidateSnapshot(snapshot);
if (result.OK())
    // Snapshot is valid. Lets use the result.
    if (snapshot["failed"])
        // User failed the RISC session. We can force a logout here, or do something fancier like track the user.
        puts 'Risc score: ' + snapshot["score"] + '%. Logging user out...';
        // TODO: force logout
    elsif (snapshot["risky"])
        // User passed the RISC session but not by much.
        puts 'Risc score: ' + snapshot["score"] + '%. User validated.';
        // TODO: redirect user to main site
    elsif (snapshot["passed"])
        // User passed the RISC session with no issues.
        puts 'Risc score: ' + snapshot["score"] + '%. User validated.';
        // TODO: redirect user to main site
    else
        // NO-MAN's land. This code should never be reached - all RISC results are either risky, passed or failed.
    end

else
    // Snapshot is invalid. This is bad news - it means your API secret likely isn't a secret, and a hacker is logging in.
	puts "Error validating snapshot: " + result.Error();
    // TODO: Panic. Call the admins. Then go to the RISC admin console and generate a new API key.
end
```


## Pre-authenticate User for a Specific Browser (optional)

The `preauth` API call can be used when a user has a high RISC score on a particular browser, but you are certain it is the correct user. This API call will effectively set the RISC score back to 0% the next time the user does a RISC snapshot from that specific browser. This can be used in a variety of scenarios, the most common being after you have performed a successful second-factor authentication for that user, and you want his next RISC snapshot to be successful.

You will need a valid user ID and browser ID to call this API function. The browser ID will be contained in the most recent RISC snapshot result.

```
SAMPLE CODE SOON
 ```

