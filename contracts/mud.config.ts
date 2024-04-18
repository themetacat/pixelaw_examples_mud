import { mudConfig } from "@latticexyz/world/register";

export default mudConfig({
  namespace: "myapp",
  enums:{
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
