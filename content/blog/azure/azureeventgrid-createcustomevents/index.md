---
title: "Azure Event Grid - Create Custom Events"
date: "2018-12-30"
categories: 
  - "azure"
---

This post is part of a three post series on Azure Event Grid

[Azure Event Grid - Introduction](https://pradeepl.com/azure/azureeventgrid-introduction)

[Azure Event Grid - Create Topics](https://pradeepl.com/azure/azureeventgrid-createtopic)

[Azure Event Grid - Creating Custom events](https://pradeepl.com/azure/azureeventgrid-createcustomevents)

An azure eventgrid event has the below schema. Azure also gives you an option to select an alternate schema called Cloud Schema. For now let's look at the event grid schema.

## Event Schema

```json
[
  {
    "topic": "string",
    "subject": "string",
    "id": "string",
    "eventType": "string",
    "eventTime": "string",
    "data": { "object-unique-to-each-publisher" },
    "dataVersion": "string",
    "metadataVersion": "string"
  }
]
```

- Topic - This field defines the topic or in case of an
- subject - This field can be used as a tag or a label by the application.
- id - An unique identifier for the event.
- eventType - The type of the published event. In the sample below I am using Candidatecreated and candidatedupdated as the event types.
- eventTime - The time when an event was published. This is in the publishers UTC time.
- data - This field is the custom data published by the event source.
- dataVersion - This field can be used by the publisher to version the data schema .

## Event Grid SDK

To create and publish custom events to Event grid we need to use the Eventgrid SDK. Install the SDK from using the package manager console as below

Install-Package Microsoft.Azure.EventGrid -Version 3.0.0

## Creating Custom Events

One of the areas where I am using azure event grid is to implement Domain events. Domain event is a well established paradigm in Domain Driven Design (DDD). [You can read more about it in this article from Martin Fowler](https://martinfowler.com/eaaDev/DomainEvent.html). In this example I am model the event signature using an interface. This interface provides two domain events which are raised when ever a candidate is created and a candidate is updated. The event signature is below.

```csharp
public interface ICandidateEvents
{
   Task CandidateCreatedEvent(Candidate candidate);
   Task CandidateUpdatedEvent(Candidate candidate);
}
```

This is the implementation of the above domain event. I have made the class much simpler to aide our understanding of Event grid. This class has three objects which help to create and fire an event

- EventGridEvent - This object represents the actual event and represents the event schema above.
- TopicCredentials - Azure Event Grid requires either the "aeg-sas-token" or the "aeg-sas-key" authorization header in the publish request. The TopicCredentials class in the SDK is used to specify this key. The key can be obtained from Azure portal.
- EventGridClient - This object is used to apply the credential and publish the event.

To publish an event we need to create an array of events. Yes, even if you need to publish a single event you need to create an array of events. In the sample code below , I am creating it as eventsList. A topic credential object is created and initialized with the access keys for that topic obtained from the azure portal. The event client is created by initializing it with the topic credential object. The event client is then used to fire the event to the grid by passing in the event list and the topic endpoint. The complete sample code is below.

```csharp
public class CandidateEvents : ICandidateEvents
    {
        string topicEndpoint;
        string topicKey ;
        string topicHostname ;
        TopicCredentials topicCredentials ;
        EventGridClient client;

        public CandidateEvents()
        {
            topicEndpoint = "https://yourtopicendpoint/api/events";
            topicKey = "yourtopickey";
            topicHostname = new Uri(topicEndpoint).Host;
            topicCredentials = new TopicCredentials(topicKey);
            client = new EventGridClient(topicCredentials);
        }

        public async Task CandidateCreatedEvent(Candidate candidate)
        {
            List<EventGridEvent> eventsList = new List<EventGridEvent>();

            EventGridEvent ev = new EventGridEvent()
            {
                Id = new Guid().ToString(),
                Data = candidate,
                EventTime = DateTime.Now,
                EventType = "Somevent.CandidateCreated",
                DataVersion = "1.0",
                Subject = candidate.CandidateName.Identifier

            };

            eventsList.Add(ev);

            await client.PublishEventsAsync(topicHostname, eventsList );
        }

        public Task CandidateUpdatedEvent(Candidate candidate)
        {
            List<EventGridEvent> eventsList = new List<EventGridEvent>();

            EventGridEvent ev = new EventGridEvent()
            {
                Id = new Guid().ToString(),
                Data = candidate,
                EventTime = DateTime.Now,
                EventType = "Somevent.CandidateUpdated",
                DataVersion = "1.0",
                Subject = candidate.CandidateName.Identifier

            };

            eventsList.Add(ev);

            await client.PublishEventsAsync(topicHostname, eventsList );
        }
    }
    ```

As shown in the previous post , I have created a subscription for this topic and have used a web hook as the handler for the subscription. The web hook points to an API. Azure Event grid now will post the event to the handler. It will retry the post until it receives a 200 or a 202 response. Event Grid uses a exponential backoff retry policy i.e. it will increase the time between retries for every failed retry. We can also specify a retry policy if necessary.

## Event Handler - Webhook

Here is the event handler code. We are deserializing the object into an array of type EventGridEvent . While subscribing to Azure Event Grid topic, the Event Grid sends a validation request to the subscribing URL endpoint with a validation code. If the endpoint echoes back the same Validation Code then Event Grid accepts that endpoint URL as a valid endpoint for subscription. We are doing this by wrapping the validation code as subscription validation response and returning a HTTP 200 status code. We can then use the other events in the list and custom process them.

```csharp
public async Task<IActionResult> Post([FromBody]object request)
{
    try
    {
        var eventGridEvent = JsonConvert.DeserializeObject<EventGridEvent[]>(request.ToString());
        
        foreach (var item in eventGridEvent)
        {
            
        if (string.Equals(item.EventType, "Microsoft.EventGrid.SubscriptionValidationEvent", StringComparison.OrdinalIgnoreCase))
                {   
                    var data = item.Data as JObject;
                    var eventData = data.ToObject<SubscriptionValidationEventData>();
                    var responseData = new SubscriptionValidationResponse
                    {
                        ValidationResponse = eventData.ValidationCode
             };
                                                
                    return Ok(responseData);
         }
            else
            {            
                await DoSomethingWithEvent(item.Data.ToString());
        }

        }
      }
      catch (Exception ex)
      {
          telemetry.TrackException(ex);
        throw;
       }

       return Ok();

} 
```

This concludes the series on Azure event grid.
