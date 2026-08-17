# SOAP Web Service API Documentation: `ShowNearbyUsers`

This document outlines the complete SOAP XML Web Service specifications for the **Nearby / Map Screen (`NearbyMapScreen`)** in the **BoomBoom Dating App**.

---

## 🌐 Endpoint Details

| Parameter | Value |
|---|---|
| **Service URL** | `https://boomboomdate.com/APIs/WebService1.asmx` |
| **Method** | `POST` |
| **Content-Type** | `text/xml; charset=utf-8` |
| **SOAPAction** | `"http://tempuri.org/ShowNearbyUsers"` |
| **Namespace** | `http://tempuri.org/` |

---

## 📤 1. Request Envelope (Flutter App ➔ Backend)

```xml
POST /APIs/WebService1.asmx HTTP/1.1
Host: boomboomdate.com
Content-Type: text/xml; charset=utf-8
Content-Length: length
SOAPAction: "http://tempuri.org/ShowNearbyUsers"

<?xml version="1.0" encoding="utf-8"?>
<soap:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">
  <soap:Body>
    <ShowNearbyUsers xmlns="http://tempuri.org/">
      <token>string</token>
      <MyEmail>user@example.com</MyEmail>
      <Lat>28.0229</Lat>
      <Lon>73.3119</Lon>
      <RadiusKm>5</RadiusKm>
      <Category>All</Category>
    </ShowNearbyUsers>
  </soap:Body>
</soap:Envelope>
```

### 📋 Request Parameters Explanation:

| Parameter | Data Type | Required | Description | Example Values |
| :--- | :--- | :--- | :--- | :--- |
| **`token`** | `string` | Yes | Security / Auth Token | `"test_token_123"` |
| **`MyEmail`** | `string` | Yes | Current logged-in user's email to exclude from search results | `"jksuthar0303@gmail.com"` |
| **`Lat`** | `string / decimal` | Yes | Current User's GPS Latitude coordinate | `"28.0229"` |
| **`Lon`** | `string / decimal` | Yes | Current User's GPS Longitude coordinate | `"73.3119"` |
| **`RadiusKm`** | `int / decimal` | Yes | Search Radius slider distance in Kilometers (`1` to `150` km) | `5`, `25`, `50` |
| **`Category`** | `string` | Optional | Selected category filter from top tabs | `"All"`, `"Crosspath"`, `"Free Tonight"`, `"Nearby"` |

---

## 📥 2. Success Response Envelope (Backend ➔ Flutter App)

```xml
HTTP/1.1 200 OK
Content-Type: text/xml; charset=utf-8
Content-Length: length

<?xml version="1.0" encoding="utf-8"?>
<soap:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">
  <soap:Body>
    <ShowNearbyUsersResponse xmlns="http://tempuri.org/">
      <ShowNearbyUsersResult>
        {
          "Status": 1,
          "Message": "Data found",
          "Data": [
            {
              "id": 10,
              "EmailAddress": "chirag@gmail.com",
              "FullName": "Chirag",
              "Dob": "1998-05-15",
              "Gender": "Male",
              "Occupation": "Software Engineer",
              "BIO": "Looking for genuine connections",
              "Lat": "28.0245",
              "Lon": "73.3150",
              "Distance": "0.4 km",
              "IsOnline": "True",
              "IsVerified": "True",
              "Category": "Nearby",
              "Media": "/9j/4QBqRXhpZgAATU0AKgAAAAgABAE..."
            },
            {
              "id": 14,
              "EmailAddress": "kapoor@gmail.com",
              "FullName": "Kapoor",
              "Dob": "1996-11-20",
              "Gender": "Male",
              "Occupation": "Entrepreneur",
              "BIO": "Coffee & conversations",
              "Lat": "28.0310",
              "Lon": "73.3210",
              "Distance": "1.2 km",
              "IsOnline": "True",
              "IsVerified": "False",
              "Category": "Crosspath",
              "Media": "https://boomboomdate.com/uploads/photo1.jpg"
            }
          ]
        }
      </ShowNearbyUsersResult>
    </ShowNearbyUsersResponse>
  </soap:Body>
</soap:Envelope>
```

---

## ❌ 3. Empty / No Data Response Envelope

```xml
HTTP/1.1 200 OK
Content-Type: text/xml; charset=utf-8

<?xml version="1.0" encoding="utf-8"?>
<soap:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">
  <soap:Body>
    <ShowNearbyUsersResponse xmlns="http://tempuri.org/">
      <ShowNearbyUsersResult>
        {
          "Status": 0,
          "Message": "No users found in this radius",
          "Data": []
        }
      </ShowNearbyUsersResult>
    </ShowNearbyUsersResponse>
  </soap:Body>
</soap:Envelope>
```

---

## ⚙️ Backend Implementation Notes

1. **Haversine Distance Query (SQL Example)**:
   ```sql
   SELECT id, EmailAddress, FullName, Dob, Gender, Occupation, BIO, Lat, Lon, IsOnline, IsVerified,
   ( 6371 * acos( cos( radians(@UserLat) ) * cos( radians( CAST(Lat AS FLOAT) ) )
   * cos( radians( CAST(Lon AS FLOAT) ) - radians(@UserLon) ) + sin( radians(@UserLat) )
   * sin( radians( CAST(Lat AS FLOAT) ) ) ) ) AS DistanceKm
   FROM Users
   WHERE EmailAddress != @MyEmail
   HAVING DistanceKm <= @RadiusKm
   ORDER BY DistanceKm ASC;
   ```
2. **Exclude Current User**: Ensure `EmailAddress != @MyEmail` so user is never returned in their own nearby results.
3. **Media Format**: `Media` property supports both **Base64 String** and **Image URL**.
