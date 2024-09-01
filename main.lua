--[[

	IEEE-754 Floating point value to binary conversion function
	2024 John Louge

	Please note: Since native Lua does not support a lot for binary conversions, (except for bit library)
	this is a lengthy and not very performent conversion function. I just wrote it for personal use
	and because no one seemed to put up one that is pure Lua.

	Little guide on the IEEE-754 floats to which this can convert is below:

	BREAKDOWN										  NAME 										CODE
	
	-- Floating-point precision values. (BTW: GitHub might mess up the presentation below!)
		   Integer						  Precision
	|	|			|								| Half Precision Floating Point 			"f16"
Sign  15  14	 10  9							  0	  (16 bits)	
	|	|			|								| Single Precision Floating Point 			"f32"
Sign  31  30	 23  22							  0	  (32 bits)
	|	|			|								| Double Precision Floating Point 			"f64"
Sign  63  62	 52  51							  0	  (64 bits)	
			    	   v-> *Integer bit
	|	|			|	|							| Double Extended Precision Floating Point 	"f80"
Sign  79  78	 64  63  62						  0	  (64 bits)	

*Note: This bit is specific to the double extended precision floating point type.
	   This bit decides whether a number like this is normalized or denormalized by being
	   set to 0 or 1 (denormalized or normalized). The number is denormalized when the
	   biased exponent is zero.
	   For what normalized/denormalized means: Normalized is all floating point data that can be
	   represented. Unnormalized occurs when the number is extremely small to represent and may
	   cause an underflow (TOO SMALL to represent.) You may also know "denormalized" as subnormal.
	   in extended types integer bit helps to represent such very small numbers. Nowadays it is 
	   not as significant, but according to wiki these are the reasons back in the day (8087 processor):

		   	" - Calculations can be completed a little faster if all bits 
		   	  of the significand are present in the register.
		   	  
		      - A 64 bit significand provides sufficient precision to avoid 
		      loss of precision when the results are converted back to
		      double-precision format in the vast number of cases.
		      
		      - This format provides a mechanism for indicating precision 
		      loss due to underflow which can be carried through further operations. 
		      For example, the calculation 2 × 10−4930 × 3 × 10−10 × 4 × 1020 generates 
		      the intermediate result 6 × 10−4940 which is a denormal and also involves precision loss.
		      The product of all of the terms is 24 × 10−4920 which can be represented as a normalized number.
		      The 80287 could complete this calculation and indicate the loss of precision by returning
		      an "denormal" result (exponent not 0, bit 63 = 0). Processors since the 80387 
		      no longer generate unnormals and do not support unnormal inputs to operations. 
		      They will generate a denormal if an underflow occurs but will generate a
		      normalized result if subsequent operations on the denormal can be normalized. "	   
]]

-- Helper functions.
function toBinary(num)
	local bin = "" 
	local rem 
	while num > 0 do
		rem = num % 2 
		bin = rem .. bin 
		num = math.floor(num / 2)
	end
	return bin 
end
function realval(value)
	local newval,segs = "0.",tostring(value):split("e-")
	if segs[2] then
		newval..=string.rep("0",tonumber(segs[2])-1) for i,v in pairs(segs[1]:split("")) do if tonumber(v) then newval..=v end end return newval
	else return value end
end
function frac_tobase(n,b)
	local frac = ""
	while n~=0 do
		n=b*n
		local newn=tonumber(tostring(realval(n)):sub(1,1))
		frac..=newn
		n-=newn
	end
	return frac
end

-- The float conversion function itself.
return function(value:number,precision)
	assert(precision,"Missing precision for float conversion")
	
	local returnvalue = value
	local bias = if precision==16 then 15 elseif precision==32 then 127 elseif precision==64 then 1023 else 2047 --Else: Extended Double Precision
	local expolen = if precision==16 then 6 elseif precision==32 then 8 elseif precision==64 then 11 else 15
	local matissalen = if precision==10 then 10 elseif precision==32 then 23 elseif precision==64 then 52 else 63
	
	local value = realval(value) -- *Real* value. Since Lua tends to use the negative exponentiation at very long fractions, this conversion is done.
	local fractioned = tonumber("0"..string.sub(tostring(value),#tostring(math.floor(tonumber(value)))+1,#tostring(value))) -- Fixed fraction value
	local matissa = string.sub(toBinary(math.floor(tonumber(value)))..frac_tobase(fractioned,2),2);matissa..=string.rep("0",matissalen-#matissa) -- Matissa/Fraction. Whatever you may call it
	matissa=if matissa:sub(matissalen+1,matissalen+1)=="1" then string.sub(matissa,1,matissalen-2).."10" else string.sub(matissa,1,matissalen-2).."00" -- Mysterious IEEE-754 roundup/down feature. To make numbers even less accurate who knows?
	return (if tonumber(value)>0 then "0" else "1")..string.format("%0"..expolen.."s",toBinary(bias+(((function() local amnt = 0 if tostring(value):split(".")[2] then for i,v in pairs(tostring(value):split(".")[2]:split("")) do if tonumber(v) and tonumber(v)==0 then amnt+=1 end end end return amnt end)())>0 and -#frac_tobase(fractioned,2):split("1")[1]-1 or #toBinary(math.floor(tonumber(value)),2)-1),2)).. matissa
end
