TASK-5506 -- Enhancement: ARMCachedSaveworkservice has been enhanced to handle multiple transactions from multiple transids. 

Single Form payload JSON format(Existing):
------------------------------------------
{
  "_parameters": [
    {
      "savedata": {
        "cachedsave": "true",
        "axpapp": "goldendump114",
        "appsessionkey": "01019867001401610153016001640150014901600154016601580161009800970104321820261111041530017",
        "transid": "tfdat",
        "s": "fkb2401kuse21fjd2ino3hkc",
        "username": "admin",
        "password": "",
        "afiles": "",
        "changedrows": {
          "dc2": "*"
        },
        "trace": "false",
        "recordid": "0",
        "recdata": [
          {
            "axp_recid1": [
              {
                "rowno": "001",
                "text": "0",
                "columns": {
                  "flda": "admin",
                  "fldb": "01/04/2026",
                  "fldc": "12:00 PM",
                  "fldd": "",
                  "dateexp": "01/04/2026",
                  "timeexp": "12:00 PM",
                  "datetime": "01/04/2026 11:04:54",
                  "datetimeexp": "01/04/2026 11:04:54"
                }
              }
            ]
          },
          {
            "axp_recid2": [
              {
                "rowno": "001",
                "text": "0",
                "columns": {
                  "gflda": "A1",
                  "gfldb": "01/04/2026",
                  "gfldc": "12:00 PM",
                  "gfldd": "A1",
                  "gdatexp": "01/04/2026",
                  "gtimeexp": "",
                  "gdatetime": ""
                }
              },
              {
                "rowno": "002",
                "text": "",
                "columns": {
                  "gflda": "B1",
                  "gfldb": "02/04/2026",
                  "gfldc": "12:22 PM",
                  "gfldd": "B1",
                  "gdatexp": "02/04/2026",
                  "gtimeexp": "12:22 PM",
                  "gdatetime": ""
                }
              }
            ]
          }
        ]
      },
      "goldendump114": {
        "type": "db",
        "structurl": "",
        "db": "Postgre",
        "driver": "dbx",
        "version": "",
        "dbcon": "localhost:5433",
        "dbuser": "goldendump114\\axpertdb",
        "pwd": "000301590161015232163450607080013",
        "dataurl": ""
      },
      "axprops": {
        "lastlogin": "goldendump114",
        "oradatestring": "dd/mm/yyyy hh24:mi:ss",
        "crlocation": "",
        "lastusername": "admin",
        "login": "local",
        "skin": "Black",
        "lastlang": "ENGLISH",
        "axhelp": "true",
        "trace": "false",
        "almconnections": "",
        "showuser": "t",
        "goldendump112": "global",
        "agilepost113": "global"
      },
      "globalvars": {
        "pusername": "admin",
        "AxUserName": "administrator"
      },
      "uservars": {}
    }
  ]
}

Multiple transactions from multiple transids payload JSON format:
-----------------------------------------------------------------
{
  "_parameters": [
    {
      "savedata": {
        "forma": {
          "transaction1": {
            "cachedsave": "true",
            "axpapp": "goldendump114",
            "appsessionkey": "01019867001401610153016001640150014901600154016601580163009800990103321820261131231090017",
            "transid": "forma",
            "s": "essvq1o43ottlv1zhyp0jgef",
            "username": "admin",
            "password": "",
            "afiles": "",
            "trace": "false",
            "recordid": "0",
            "changedrows": {},
            "recdata": [
              {
                "axp_recid1": [
                  {
                    "rowno": "001",
                    "text": "0",
                    "columns": {
                      "flda": "test",
                      "fldb": "admin",
                      "fldc": "",
                      "fldd": "",
                      "fldNum": "",
                      "fldpwd": ""
                    }
                  }
                ]
              }
            ]
          },
          "transaction2": {
            "cachedsave": "true",
            "axpapp": "goldendump114",
            "appsessionkey": "01019867001401610153016001640150014901600154016601580163009800990103321820261131231090017",
            "transid": "forma",
            "s": "essvq1o43ottlv1zhyp0jgef",
            "username": "admin",
            "password": "",
            "afiles": "",
            "trace": "false",
            "recordid": "0",
            "changedrows": {},
            "recdata": [
              {
                "axp_recid1": [
                  {
                    "rowno": "001",
                    "text": "0",
                    "columns": {
                      "flda": "test2",
                      "fldb": "malakonda",
                      "fldc": "",
                      "fldd": "",
                      "fldNum": "",
                      "fldpwd": ""
                    }
                  }
                ]
              }
            ]
          }
        },
        "formb": {
          "transaction1": {
            "cachedsave": "true",
            "axpapp": "goldendump114",
            "appsessionkey": "01019867001401610153016001640150014901600154016601580163009800990103321820261131231090017",
            "transid": "formb",
            "s": "essvq1o43ottlv1zhyp0jgef",
            "username": "admin",
            "password": "",
            "afiles": "",
            "trace": "false",
            "recordid": "0",
            "changedrows": {
              "dc2": "*"
            },
            "recdata": [
              {
                "axp_recid1": [
                  {
                    "rowno": "001",
                    "text": "0",
                    "columns": {
                      "flda": "A1",
                      "fldb": "a",
                      "fldc": "3.00"
                    }
                  }
                ]
              },
              {
                "axp_recid2": [
                  {
                    "rowno": "001",
                    "text": "0",
                    "columns": {
                      "fldd": "a",
                      "flde": "A1"
                    }
                  },
                  {
                    "rowno": "002",
                    "text": "",
                    "columns": {
                      "fldd": "b",
                      "flde": "A1"
                    }
                  }
                ]
              }
            ]
          }
        },
        "formc": {
          "transaction1": {
            "cachedsave": "true",
            "axpapp": "goldendump114",
            "appsessionkey": "01019867001401610153016001640150014901600154016601580163009800990103321820261131231090017",
            "transid": "formc",
            "s": "essvq1o43ottlv1zhyp0jgef",
            "username": "admin",
            "password": "",
            "afiles": "",
            "trace": "false",
            "recordid": "0",
            "changedrows": {
              "dc2": "*"
            },
            "recdata": [
              {
                "axp_recid1": [
                  {
                    "rowno": "001",
                    "text": "0",
                    "columns": {
                      "flda": "C1",
                      "fldb": "cc",
                      "fldc": ""
                    }
                  }
                ]
              },
              {
                "axp_recid2": [
                  {
                    "rowno": "001",
                    "text": "0",
                    "columns": {
                      "fldd": "c",
                      "flde": "44.00",
                      "fldf": "01/04/2026"
                    }
                  },
                  {
                    "rowno": "002",
                    "text": "",
                    "columns": {
                      "fldd": "d",
                      "flde": "4.00",
                      "fldf": ""
                    }
                  }
                ]
              }
            ]
          }
        }
      },
      "goldendump114": {
        "type": "db",
        "structurl": "",
        "db": "Postgre",
        "driver": "dbx",
        "version": "",
        "dbcon": "localhost:5433",
        "dbuser": "goldendump114\\axpertdb",
        "pwd": "000301590161015232163450607080013",
        "dataurl": ""
      },
      "axprops": {
        "lastlogin": "goldendump114",
        "oradatestring": "dd/mm/yyyy hh24:mi:ss",
        "crlocation": "",
        "lastusername": "admin",
        "login": "local",
        "skin": "Black",
        "lastlang": "ENGLISH",
        "axhelp": "true",
        "trace": "false",
        "almconnections": "",
        "showuser": "t",
        "goldendump112": "global",
        "agilepost113": "global"
      },
      "globalvars": {
        "pusername": "admin",
        "AxUserName": "administrator"
      },
      "uservars": {}
    }
  ]
}

