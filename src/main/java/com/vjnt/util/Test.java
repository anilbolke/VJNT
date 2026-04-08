package com.vjnt.util;

import org.json.JSONArray;
import org.json.JSONObject;

public class Test {

	
	public static void main(String[] args) {
		
		String body = "{\r\n"
				+ "    \"Transaction\": [\r\n"
				+ "        {\r\n"
				+ "            \"TransactionDetails\": {\r\n"
				+ "                \"ValueDate\": \"06-04-2026\",\r\n"
				+ "                \"CustomerReference\": \"PETRONIN06042026100001\",\r\n"
				+ "                \"PartnerBranchcode\": \"40101\",\r\n"
				+ "                \"TranDate\": \"06-04-2026\",\r\n"
				+ "                \"Mode\": \"TT\",\r\n"
				+ "                \"InstrumentNo\": \"1528943982\",\r\n"
				+ "                \"Currency\": \"EUR\",\r\n"
				+ "                \"Amount\": \"10\",\r\n"
				+ "                \"Rate\": \"86000.9640\",\r\n"
				+ "                \"INR\": \"8600.9640\",\r\n"
				+ "                \"DealID\": \"13930029\"\r\n"
				+ "            },\r\n"
				+ "            \"RemitterDetails\": {\r\n"
				+ "                \"RemitterFName\": \"Atulkumar\",\r\n"
				+ "                \"RemitterMName\": \"\",\r\n"
				+ "                \"RemitterLName\": \"Dubey\",\r\n"
				+ "                \"RemitterType\": \"Individual\",\r\n"
				+ "                \"RemitterAddress\": \"A898, 5th Flr, Opp Railay Stn Koparkhairane, Near Mcdonalds\",\r\n"
				+ "                \"RemitterCity\": \"MAHARASHTRA\",\r\n"
				+ "                \"RemitterCountry\": \"INDIA\",\r\n"
				+ "                \"RemitterPAN\": \"AAAPU0916F\"\r\n"
				+ "            },\r\n"
				+ "            \"BeneficiaryDetails\": {\r\n"
				+ "                \"BeneficiaryFName\": \"manish\",\r\n"
				+ "                \"BeneficiaryMName\": \"\",\r\n"
				+ "                \"BeneficiaryLName\": \"test\",\r\n"
				+ "                \"BeneficiaryType\": \"Individual\",\r\n"
				+ "                \"BeneficiaryAddress\": \"test\",\r\n"
				+ "                \"BeneCity\": \"\",\r\n"
				+ "                \"BeneCountry\": \"india\",\r\n"
				+ "                \"BeneficiaryAcNo\": \"734891\"\r\n"
				+ "            },\r\n"
				+ "            \"BankDetails\": {\r\n"
				+ "                \"BeneBankName\": \"\",\r\n"
				+ "                \"BeneBankAddress\": \"\",\r\n"
				+ "                \"BeneBankCountry\": \"US\",\r\n"
				+ "                \"BeneBankSWIFTDetails\": \"ICICUS3N\",\r\n"
				+ "                \"BeneBankSORTCode\": \"\"\r\n"
				+ "            },\r\n"
				+ "            \"IntermBankDetails\": {\r\n"
				+ "                \"IntermBankName\": \"\",\r\n"
				+ "                \"IntermAddress\": \"\",\r\n"
				+ "                \"IntermBICCode\": \"\",\r\n"
				+ "                \"Intermbankcountry\": \"\",\r\n"
				+ "                \"Intermsortcode\": \"\"\r\n"
				+ "            },\r\n"
				+ "            \"OtherDetails\": {\r\n"
				+ "                \"Purposecode\": \"S1302\",\r\n"
				+ "                \"EducationalDetails\": \"\",\r\n"
				+ "                \"CorrespondentBankCharges\": \"\",\r\n"
				+ "                \"FBCharges\": \"OUR\",\r\n"
				+ "                \"MerchantUserIdentity\": \"Individual\",\r\n"
				+ "                \"AdditionalField1\": \"\",\r\n"
				+ "                \"AdditionalField2\": \"Yes\",\r\n"
				+ "                \"AdditionalField3\": \"\",\r\n"
				+ "                \"AdditionalField4\": \"1528943982\",\r\n"
				+ "                \"AdditionalField5\": \"565434\",\r\n"
				+ "                \"AdditionalField6\": \"\",\r\n"
				+ "                \"AdditionalField7\": \"\",\r\n"
				+ "                \"AdditionalField8\": \"\",\r\n"
				+ "                \"AdditionalField9\": \"01-05-1997\",\r\n"
				+ "                \"AdditionalField10\": \"suhas\",\r\n"
				+ "                \"NewgenCPUMaker\": \"maker\",\r\n"
				+ "                \"NewgenCPUMakerTimestamp\": \"07/09/2023 13:17:14.297\",\r\n"
				+ "                \"NewgenCPUChecker\": \"checker\",\r\n"
				+ "                \"NewgenCPUCheckerTimestamp\": \"07/09/2023 15:17:14.297\"\r\n"
				+ "            }\r\n"
				+ "        }\r\n"
				+ "    ]\r\n"
				+ "}";
		JSONObject jsonObject 						= new JSONObject(body.trim());
			JSONArray jsonArr 							=  jsonObject.getJSONArray("Transaction");
			JSONObject filedsData  	= (JSONObject) jsonArr.get(0);
			
			System.out.println(filedsData.getJSONObject("TransactionDetails").getString("CustomerReference"));
	}
}
