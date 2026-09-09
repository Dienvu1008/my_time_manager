package com.dienvu.time_manager.models

class Attendee(
    val emailAddress: String,
    val name: String?,
    val role: Int,
    val attendanceStatus: Int?,
    val isOrganizer: Boolean?,
    val isCurrentUser: Boolean?
)