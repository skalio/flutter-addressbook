package com.skalio.addressbook

import android.Manifest
import android.app.Activity
import android.content.Context
import android.content.pm.PackageManager
import android.provider.ContactsContract
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
import io.flutter.plugin.common.PluginRegistry.Registrar

/** AddressbookPlugin */
class AddressbookPlugin: FlutterPlugin, MethodCallHandler, PluginRegistry.RequestPermissionsResultListener, ActivityAware {
  /// The MethodChannel that will the communication between Flutter and native Android
  ///
  /// This local reference serves to register the plugin with the Flutter Engine and unregister it
  /// when the Flutter Engine is detached from the Activity
  private lateinit var channel : MethodChannel

  private var currentActivity: Activity? = null

  private lateinit var applicationContext : Context

  private val permissionCode = 1337;

  private lateinit var getContactsResult : Result

  private lateinit var getContactsMethodCall : MethodCall

  private val TAG = "123"

  //private var permissionGranted : Boolean = false;

  override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    channel = MethodChannel(flutterPluginBinding.binaryMessenger, "addressbook")
    channel.setMethodCallHandler(this)

    applicationContext = flutterPluginBinding.applicationContext;
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
      if(checkAndRequestPermission()) {
        queryContacts();
      }
    } else {
      result.notImplemented()
    }
  }

  // Returns true if the permission is already granted and false if the permission was rejected or is currently being requested
  fun checkAndRequestPermission() : Boolean {
    var permissionGranted = ContextCompat.checkSelfPermission(applicationContext,
            Manifest.permission.READ_CONTACTS) ==
            PackageManager.PERMISSION_GRANTED
    if ( !permissionGranted ) {
      ActivityCompat.requestPermissions(currentActivity!!,
              arrayOf(Manifest.permission.READ_CONTACTS),
              permissionCode )
      return false
    }
    return permissionGranted
  }

  override fun onRequestPermissionsResult(requestCode: Int, permissions: Array<out String>?, grantResults: IntArray?): Boolean {
    when (requestCode) {
      permissionCode -> {
        if ( null != grantResults &&
                grantResults.isNotEmpty() &&
                grantResults.get(0) == PackageManager.PERMISSION_GRANTED ) {
          // permission granted
          queryContacts()
        }
        else {
          // permission rejected
          // TODO throw some typed error/exception
        }
        // marks the handling of this [requestCode] as true
        return true
      }
    }
    // not our requestCode => marks the handling of it as false
    return false
  }

  fun queryContacts() {

    var contacts = hashMapOf<String, Any>(
            "giveName" to "Kate",
            "organization" to "Creative Consulting",
            "familyName" to "Bell",
            "emailAddresses" to hashMapOf<String, String>(
                    "work" to "kate-bell@mac.com"
            ),
            "phoneNumbers" to hashMapOf<String, String>(
                    "main" to "(415) 555-3695",
                    "mobile" to "(555) 564-8583"
            )

    )

    val cr = applicationContext.contentResolver
    /*val c = mutableListOf<HashMap<String, Any>>()

    var cursor = cr.query(
            ContactsContract.Data.CONTENT_URI,
            arrayOf(
                    ContactsContract.CommonDataKinds.StructuredName.CONTACT_ID,
                    ContactsContract.CommonDataKinds.StructuredName.GIVEN_NAME,
                    ContactsContract.CommonDataKinds.StructuredName.FAMILY_NAME,
                    ContactsContract.CommonDataKinds.Organization.COMPANY
            ),
            "${ContactsContract.CommonDataKinds.StructuredName.GIVEN_NAME} IS NOT NULL"
            + " OR ${ContactsContract.CommonDataKinds.StructuredName.FAMILY_NAME} IS NOT NULL",
            emptyArray(),
            null)
    if (cursor != null) {
      while(cursor.moveToNext()) {
        val id : Int = cursor.getInt(0)
        val givenName : String = cursor.getString(1)  ?: "null"
        val familyName : String = cursor.getString(2)  ?: "null"
        val organization : String = cursor.getString(3)  ?: "null"

        val map = hashMapOf<String, Any>(
                "id" to id,
                "givenName" to givenName,
                "familyName" to familyName,
                "organization" to organization
        )
        c.add(map)
        Log.d(TAG, map.toString())
        Log.d(TAG, "-------")
      }

      cursor.close()
    }

    Log.d(TAG, "======================================================================================================================")
    */
    val c = mutableListOf<HashMap<String, Any>>()
      val basicCursor = cr.query(
              ContactsContract.Contacts.CONTENT_URI,
              arrayOf(
                      ContactsContract.Contacts._ID,
                      ContactsContract.Contacts.DISPLAY_NAME
              ),
              null,
              emptyArray(),
              null
      )
      if (basicCursor != null) {
        while(basicCursor.moveToNext()) {
          val id : Int = basicCursor.getInt(0)
          val displayName : String = basicCursor.getString(1)  ?: "null"

          val dataCursor = cr.query(
                  ContactsContract.Data.CONTENT_URI,
          arrayOf(
                  ContactsContract.CommonDataKinds.StructuredName.CONTACT_ID,
                  ContactsContract.CommonDataKinds.StructuredName.GIVEN_NAME,
                  ContactsContract.CommonDataKinds.StructuredName.FAMILY_NAME,
                  ContactsContract.CommonDataKinds.Organization.COMPANY,
                  ContactsContract.CommonDataKinds.Email.
          ),
          "${ContactsContract.CommonDataKinds.StructuredName.CONTACT_ID} = $id",
          emptyArray(),
          null
          )

          if(dataCursor != null) {
            dataCursor.moveToFirst()
            val givenName : String = dataCursor.getString(dataCursor.getColumnIndex(ContactsContract.CommonDataKinds.StructuredName.FAMILY_NAME))  ?: "null"
            val familyName : String = dataCursor.getString(dataCursor.getColumnIndex(ContactsContract.CommonDataKinds.StructuredName.FAMILY_NAME))  ?: "null"
            val organization : String = dataCursor.getString(dataCursor.getColumnIndex(ContactsContract.CommonDataKinds.Organization.COMPANY))  ?: "null"
            dataCursor.close();

            val map = hashMapOf<String, Any>(
                    "id" to id,
                    "displayName" to displayName,
                    "givenName" to givenName,
                    "familyName" to familyName,
                    "organization" to organization
            )
            c.add(map)
          }



          Log.d(TAG, c.toString())
          Log.d(TAG, "-------")
        }

        basicCursor.close()
    }

    getContactsResult?.success(listOf(contacts))
  }

}
