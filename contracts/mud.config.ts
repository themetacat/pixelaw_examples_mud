import { mudConfig } from "@latticexyz/world/register";

export default mudConfig({
  namespace: "myapp",
  enums:{
    TestEnum: ["Q", "W", "E", "R", "T", "Y"],
    TestEnumTwo: ["A", "S", "D", "F", "G"],
  },
  tables: {


  },
  systems: {
    MyAppSystem: {
      name: "MyAppSystem",
      openAccess: true
    },
    
  }
});
