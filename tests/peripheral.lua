if not shouldExist( "peripheral", peripheral ) then return end

shouldExist( "peripheral.getNames", peripheral.getNames )
shouldExist( "peripheral.isPresent", peripheral.isPresent )
shouldExist( "peripheral.getType", peripheral.getType )
shouldExist( "peripheral.hasType", peripheral.hasType )
shouldExist( "peripheral.getMethods", peripheral.getMethods )
shouldExist( "peripheral.call", peripheral.call )
shouldExist( "peripheral.wrap", peripheral.wrap )
shouldExist( "peripheral.find", peripheral.find )