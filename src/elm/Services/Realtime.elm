module Services.Realtime exposing (RealtimeData, RealtimeEvent, onMessage, subscribe, unsubscribe)

import Json.Decode as JD
import Json.Encode as JE
import Services.EventManager as EventManager


type RealtimeEvent
    = IndexEvent
    | ShowEvent


type alias RealtimeData =
    { data : Maybe JD.Value
    , event : RealtimeEvent
    }


subscribe : String -> Cmd msg
subscribe topic =
    Cmd.batch
        [ EventManager.emit
            (EventManager.makeCustomEventName "realtime:subscribe-topic")
            (EventManager.withPayload
                (JE.object
                    [ ( "topic", JE.string ("realtime:" ++ topic) )
                    ]
                )
            )
        , EventManager.listen
            (EventManager.makeCustomEventName ("realtime:" ++ topic))
        ]


unsubscribe : String -> Cmd msg
unsubscribe topic =
    Cmd.batch
        [ EventManager.emit
            (EventManager.makeCustomEventName "realtime:unsubscribe-topic")
            (EventManager.withPayload
                (JE.object
                    [ ( "topic", JE.string ("realtime:" ++ topic) )
                    ]
                )
            )
        , EventManager.removeListener
            (EventManager.makeCustomEventName ("realtime:" ++ topic))
        ]


onMessage : String -> msg -> (Result EventManager.EventError RealtimeData -> msg) -> Sub msg
onMessage topic ignoredEventMsg mapper =
    EventManager.onEvent
        (EventManager.makeCustomEventName ("realtime:" ++ topic))
        ignoredEventMsg
        realtimeDecoder
        mapper


realtimeDecoder : JD.Decoder RealtimeData
realtimeDecoder =
    JD.map2 RealtimeData
        (JD.maybe (JD.field "data" JD.value))
        (JD.field "event" (JD.string |> JD.andThen eventDecoder))


eventDecoder : String -> JD.Decoder RealtimeEvent
eventDecoder event =
    case event of
        "index" ->
            JD.succeed IndexEvent

        "show" ->
            JD.succeed ShowEvent

        t ->
            JD.fail ("Unknown event " ++ t)
