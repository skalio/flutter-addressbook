package com.skalio.addressbook

import android.Manifest
import android.app.Activity
import android.content.ContentUris
import android.content.Context
import android.content.pm.PackageManager
import android.database.Cursor
import android.net.Uri
import android.provider.ContactsContract
import android.util.Base64
import android.util.Log
import androidx.annotation.NonNull
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry


/** AddressbookPlugin */
class AddressbookPlugin : FlutterPlugin, MethodCallHandler, PluginRegistry.RequestPermissionsResultListener, ActivityAware {
    private lateinit var channel: MethodChannel

    private var currentActivity: Activity? = null

    private lateinit var applicationContext: Context

    private val permissionCode = 1337

    private lateinit var getContactsResult: Result

    private lateinit var getContactsMethodCall: MethodCall

    override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "addressbook")
        channel.setMethodCallHandler(this)

        applicationContext = flutterPluginBinding.applicationContext
    }

    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }

    override fun onDetachedFromActivity() {
        currentActivity = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        currentActivity = binding.activity
        binding.addRequestPermissionsResultListener(this)
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        currentActivity = binding.activity
        binding.addRequestPermissionsResultListener(this)
    }

    override fun onDetachedFromActivityForConfigChanges() {
        currentActivity = null
    }


    override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
        if (call.method == "getContacts") {
            getContactsMethodCall = call
            getContactsResult = result
            if (checkAndRequestPermission()) {
                queryContacts()
            }
        } else {
            result.notImplemented()
        }
    }

    // Returns true if the permission is already granted and false if the permission was rejected or is currently being requested
    private fun checkAndRequestPermission(): Boolean {
        val permissionGranted = ContextCompat.checkSelfPermission(applicationContext,
                Manifest.permission.READ_CONTACTS) ==
                PackageManager.PERMISSION_GRANTED
        if (!permissionGranted) {
            ActivityCompat.requestPermissions(currentActivity!!,
                    arrayOf(Manifest.permission.READ_CONTACTS),
                    permissionCode)
            return false
        }
        return permissionGranted
    }
    
    override fun onRequestPermissionsResult(requestCode: Int,permissions: Array<out String>, grantResults: IntArray): Boolean {
        when (requestCode) {
            permissionCode -> {
                if (grantResults.isNotEmpty() &&
                    grantResults[0] == PackageManager.PERMISSION_GRANTED) {
                    // permission granted
                    queryContacts()
                } else {
                    // permission rejected
                    // TODO throw a typed exception here that is part of the plugins documentation
                }
                // marks the handling of this [requestCode] as true
                return true
            }
        }
        // not our requestCode => marks the handling of it as false
        return false
    }

    private fun queryContacts() {
        // parse function call parameters
        val onlyWithEmail: Boolean = getContactsMethodCall.argument<Boolean>("onlyWithEmail")
                ?: false
        val profileImageFlag: Boolean = getContactsMethodCall.argument<Boolean>("profileImage")
                ?: false
        val query: String? = getContactsMethodCall.argument<String>("query")

        val cr = applicationContext.contentResolver

        val contacts = mutableListOf<Map<String, Any>>()
        val contactIds = mutableSetOf<String>()

        // assemble all the IDs of contacts that are of interest
        if (query == null || query.isEmpty()) {
            // query all contacts with a display name if no query string was provided
            val contactsCur = cr.query(ContactsContract.Contacts.CONTENT_URI,
                    null,
                    "${ContactsContract.Contacts.DISPLAY_NAME} IS NOT NULL",
                    null,//arrayOf(ContactsContract.Contacts.DISPLAY_NAME),
                    null)
            while (contactsCur != null && contactsCur.moveToNext()) {
                val id = contactsCur.getString(
                        contactsCur.getColumnIndex(ContactsContract.Contacts._ID))
                contactIds.add(id)
            }
            contactsCur?.close()
        } else {
            // else query and match the query string with a prefix- and suffix-wildcard against display names and email addresses
            val contactsCur = cr.query(ContactsContract.Contacts.CONTENT_URI,
                    null,
                    "${ContactsContract.Contacts.DISPLAY_NAME} LIKE ?",
                    arrayOf("%$query%"),//arrayOf(ContactsContract.Contacts.DISPLAY_NAME),
                    null)
            while (contactsCur != null && contactsCur.moveToNext()) {
                val id = contactsCur.getString(
                        contactsCur.getColumnIndex(ContactsContract.Contacts._ID))
                contactIds.add(id)
            }
            contactsCur?.close()

            val emailCur = cr.query(
                    ContactsContract.CommonDataKinds.Email.CONTENT_URI,
                    null,
                    ContactsContract.CommonDataKinds.Email.ADDRESS + " LIKE ?",
                    arrayOf("%$query%"),
                    null)
            while (emailCur != null && emailCur.moveToNext()) {
                val id = emailCur.getString(emailCur.getColumnIndex(
                        ContactsContract.CommonDataKinds.Email.CONTACT_ID))
                contactIds.add(id)
            }
            emailCur?.close()
        }


        for (id in contactIds) {

            val contact = mutableMapOf<String, Any>()

            // query the given name and family name
            val nameCur = cr.query(ContactsContract.Data.CONTENT_URI,
                    null,
                    ContactsContract.Data.MIMETYPE + " = ? AND " + ContactsContract.CommonDataKinds.StructuredName.CONTACT_ID + " = ?",
                    arrayOf(ContactsContract.CommonDataKinds.StructuredName.CONTENT_ITEM_TYPE, id),
                    ContactsContract.CommonDataKinds.StructuredName.GIVEN_NAME)
            if (nameCur == null || !nameCur.moveToFirst()) continue
            val givenName = nameCur.getString(nameCur.getColumnIndex(ContactsContract.CommonDataKinds.StructuredName.GIVEN_NAME))
            val familyName = nameCur.getString(nameCur.getColumnIndex(ContactsContract.CommonDataKinds.StructuredName.FAMILY_NAME))
            nameCur.close()
            // skip this contact if both names are null
            if (givenName == null && familyName == null)
                continue


            // query the email addresses
            val emailMap = mutableMapOf<String, String>()
            val emailCur = cr.query(
                    ContactsContract.CommonDataKinds.Email.CONTENT_URI,
                    null,
                    ContactsContract.CommonDataKinds.Email.CONTACT_ID + " = ?", arrayOf(id),
                    null)
            while (emailCur != null && emailCur.moveToNext()) {
                val emailAddress = emailCur.getString(emailCur.getColumnIndex(
                        ContactsContract.CommonDataKinds.Email.ADDRESS))
                val emailTypeLabel = when (emailCur.getInt(emailCur.getColumnIndex(ContactsContract.CommonDataKinds.Email.TYPE))) {
                    ContactsContract.CommonDataKinds.Email.TYPE_WORK -> "work"
                    ContactsContract.CommonDataKinds.Email.TYPE_HOME -> "home"
                    ContactsContract.CommonDataKinds.Email.TYPE_MOBILE -> "mobile"
                    ContactsContract.CommonDataKinds.Email.TYPE_CUSTOM -> "custom"
                    ContactsContract.CommonDataKinds.Email.TYPE_OTHER -> "other"
                    else -> "other"
                }
                emailMap[emailTypeLabel] = emailAddress
            }
            emailCur?.close()
            // skip this contact if the onlyWithEmail parameter is true and no emails were found
            if (onlyWithEmail && emailMap.isEmpty()) continue


            // query the organization
            var organization: String? = null
            val orgCur = cr.query(
                    ContactsContract.Data.CONTENT_URI,
                    null,
                    ContactsContract.CommonDataKinds.Organization.CONTACT_ID + " = ? AND " + ContactsContract.Data.MIMETYPE + " = ?",
                    arrayOf(
                            id,
                            ContactsContract.CommonDataKinds.Organization.CONTENT_ITEM_TYPE),
                    null)
            if (orgCur != null && orgCur.moveToNext()) {
                organization = orgCur.getString(orgCur.getColumnIndex(ContactsContract.CommonDataKinds.Organization.COMPANY))
            }
            orgCur?.close()

            // query the phone numbers
            val phoneMap = mutableMapOf<String, String>()
            val phoneCur = cr.query(
                    ContactsContract.CommonDataKinds.Phone.CONTENT_URI,
                    null,
                    ContactsContract.CommonDataKinds.Phone.CONTACT_ID + " = ?", arrayOf(id),
                    null)
            while (phoneCur != null && phoneCur.moveToNext()) {
                val phoneNumber = phoneCur.getString(phoneCur.getColumnIndex(
                        ContactsContract.CommonDataKinds.Phone.NUMBER))
                val phoneTypeLabel = when (phoneCur.getInt(phoneCur.getColumnIndex(ContactsContract.CommonDataKinds.Phone.TYPE))) {
                    ContactsContract.CommonDataKinds.Phone.TYPE_WORK -> "work"
                    ContactsContract.CommonDataKinds.Phone.TYPE_HOME -> "home"
                    ContactsContract.CommonDataKinds.Phone.TYPE_MOBILE -> "mobile"
                    ContactsContract.CommonDataKinds.Phone.TYPE_CUSTOM -> "custom"
                    ContactsContract.CommonDataKinds.Phone.TYPE_OTHER -> "other"
                    else -> "other"
                }
                phoneMap[phoneTypeLabel] = phoneNumber
            }
            phoneCur?.close()


            // query the profile image in a small thumbnail size
            var photo: String? = null
            if (profileImageFlag) {
                val contactUri: Uri = ContentUris.withAppendedId(ContactsContract.Contacts.CONTENT_URI, id.toLong())
                val photoUri: Uri = Uri.withAppendedPath(contactUri, ContactsContract.Contacts.Photo.CONTENT_DIRECTORY)
                val photoCur = cr.query(photoUri, arrayOf(ContactsContract.Contacts.Photo.PHOTO), null, null, null)

                if (photoCur != null && photoCur.moveToFirst()) {
                    val data: ByteArray = photoCur.getBlob(0)
                    // dart:convert expects Base64 to not be wrapped in contrast to RFC 2045 which requires Base64 strings to be wrapped with a newline after 76 characters
                    photo = Base64.encodeToString(data, Base64.NO_WRAP)
                }
                photoCur?.close()
            }


            // assemble the result into a map
            if (givenName != null)
                contact["givenName"] = givenName
            if (familyName != null)
                contact["familyName"] = familyName
            if (organization != null)
                contact["organization"] = organization
            if (profileImageFlag && photo != null)
                contact["profileImage"] = photo
            if (emailMap.isNotEmpty())
                contact["emailAddresses"] = emailMap
            if (phoneMap.isNotEmpty())
                contact["phoneNumbers"] = phoneMap


            contacts.add(contact)
        }

        getContactsResult.success(contacts)
    }

}
