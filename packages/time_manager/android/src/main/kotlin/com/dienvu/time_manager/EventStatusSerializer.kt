package com.dienvu.time_manager

import com.dienvu.time_manager.models.EventStatus
import com.google.gson.JsonElement
import com.google.gson.JsonObject
import com.google.gson.JsonPrimitive
import com.google.gson.JsonSerializationContext
import com.google.gson.JsonSerializer
import java.lang.reflect.Type

class EventStatusSerializer: JsonSerializer<EventStatus> {
    override fun serialize(src: EventStatus?, typeOfSrc: Type?, context: JsonSerializationContext?): JsonElement {
        if(src != null) {
            return JsonPrimitive(src.name)
        }
        return JsonObject()
    }

}