package com.vjnt.util;

import java.io.File;
import java.io.IOException;
import java.util.*;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

/**
 * Utility class to extract weekly activity data from PDF files
 * This class parses PDF content and extracts week-wise activity data
 */
public class PDFDataExtractor {
    
    private static final Map<String, String> LANGUAGE_FILE_MAP = new HashMap<>();
    private static final Map<String, Integer> DAY_ORDER = new HashMap<>();
    
    static {
        LANGUAGE_FILE_MAP.put("Marathi", "/WebContent/Weekdays/V10 Marathi Book.pdf");
        LANGUAGE_FILE_MAP.put("English", "/WebContent/Weekdays/V10 English Book New.pdf");
        LANGUAGE_FILE_MAP.put("Math", "/WebContent/Weekdays/V10 Maths Book.pdf");
        
        DAY_ORDER.put("Monday", 1);
        DAY_ORDER.put("Tuesday", 2);
        DAY_ORDER.put("Wednesday", 3);
        DAY_ORDER.put("Thursday", 4);
        DAY_ORDER.put("Friday", 5);
        DAY_ORDER.put("Saturday", 6);
    }
    
    /**
     * Extracts activity data from PDF based on language selection
     * @param language - The language (Marathi, English, or Math)
     * @param pdfFilePath - Path to the PDF file
     * @return Map of week number to daily activities
     */
    public static Map<Integer, Map<String, String>> extractActivityData(String language, String pdfFilePath) {
        Map<Integer, Map<String, String>> weeklyActivities = new LinkedHashMap<>();
        
        try {
            // For now, return sample structured data
            // This can be enhanced with actual PDF parsing using Apache PDFBox or iText
            weeklyActivities = generateSampleData(language);
        } catch (Exception e) {
            e.printStackTrace();
        }
        
        return weeklyActivities;
    }
    
    /**
     * Generate sample data structure for weekly activities
     * This structure matches the PDF data format
     * @param language - The language
     * @return Structured weekly activities
     */
    public static Map<Integer, Map<String, String>> generateSampleData(String language) {
        Map<Integer, Map<String, String>> weeklyData = new LinkedHashMap<>();
        
        String[] days = {"Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"};
        
        // Generate 14 weeks of data (one full term)
        for (int week = 1; week <= 14; week++) {
            Map<String, String> weekData = new LinkedHashMap<>();
            
            for (String day : days) {
                String activity = generateActivityForDay(language, week, day);
                weekData.put(day, activity);
            }
            
            weeklyData.put(week, weekData);
        }
        
        return weeklyData;
    }
    
    /**
     * Generate activity description based on language, week, and day
     * This should be replaced with actual PDF parsing logic
     */
    private static String generateActivityForDay(String language, int week, String day) {
        StringBuilder activity = new StringBuilder();
        
        switch (language.toLowerCase()) {
            case "marathi":
                activity.append(String.format("मराठी - आठवडा %d, %s: ", week, translateDay(day)));
                activity.append("पाठ वाचन, व्याकरण अभ्यास, लेखन कौशल्य विकास");
                break;
                
            case "english":
                activity.append(String.format("English - Week %d, %s: ", week, day));
                activity.append("Reading comprehension, Grammar practice, Writing skills development");
                break;
                
            case "math":
                activity.append(String.format("गणित - आठवडा %d, %s: ", week, translateDay(day)));
                activity.append("संख्या ज्ञान, गणितीय संक्रिया, समस्या सोडवण्याचे कौशल्य");
                break;
        }
        
        return activity.toString();
    }
    
    /**
     * Translate day name to Marathi
     */
    private static String translateDay(String day) {
        Map<String, String> dayTranslation = new HashMap<>();
        dayTranslation.put("Monday", "सोमवार");
        dayTranslation.put("Tuesday", "मंगळवार");
        dayTranslation.put("Wednesday", "बुधवार");
        dayTranslation.put("Thursday", "गुरुवार");
        dayTranslation.put("Friday", "शुक्रवार");
        dayTranslation.put("Saturday", "शनिवार");
        
        return dayTranslation.getOrDefault(day, day);
    }
    
    /**
     * Parse PDF file path for the given language
     */
    public static String getPDFFilePath(String language) {
        return LANGUAGE_FILE_MAP.getOrDefault(language, "");
    }
    
    /**
     * Get all supported languages
     */
    public static List<String> getSupportedLanguages() {
        return new ArrayList<>(LANGUAGE_FILE_MAP.keySet());
    }
    
    /**
     * Validate if PDF file exists and is readable
     */
    public static boolean isPDFAvailable(String pdfFilePath) {
        try {
            File file = new File(pdfFilePath);
            return file.exists() && file.canRead();
        } catch (Exception e) {
            return false;
        }
    }
    
    /**
     * Extract week-wise breakdown from raw PDF text
     * This method can be enhanced to use PDFBox for actual PDF parsing
     */
    public static Map<Integer, String> extractWeeklyContent(String rawPDFText) {
        Map<Integer, String> weekContent = new LinkedHashMap<>();
        
        // Pattern to identify weeks in PDF
        Pattern weekPattern = Pattern.compile("(?:Week|आठवडा)\\s*(\\d{1,2})", Pattern.CASE_INSENSITIVE);
        
        String[] lines = rawPDFText.split("\n");
        StringBuilder currentWeekContent = new StringBuilder();
        int currentWeek = 0;
        
        for (String line : lines) {
            Matcher matcher = weekPattern.matcher(line);
            if (matcher.find()) {
                int weekNum = Integer.parseInt(matcher.group(1));
                
                if (currentWeek > 0 && currentWeek <= 14) {
                    weekContent.put(currentWeek, currentWeekContent.toString().trim());
                }
                
                currentWeek = weekNum;
                currentWeekContent = new StringBuilder();
            } else if (currentWeek > 0) {
                currentWeekContent.append(line).append("\n");
            }
        }
        
        // Add last week
        if (currentWeek > 0 && currentWeek <= 14) {
            weekContent.put(currentWeek, currentWeekContent.toString().trim());
        }
        
        return weekContent;
    }
    
    /**
     * Parse daily activities from week content
     */
    public static Map<String, String> extractDailyActivities(String weekContent) {
        Map<String, String> dailyActivities = new LinkedHashMap<>();
        String[] days = {"Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"};
        
        for (String day : days) {
            Pattern dayPattern = Pattern.compile(day + ".*?(?=(?:Monday|Tuesday|Wednesday|Thursday|Friday|Saturday|$))", 
                                                Pattern.CASE_INSENSITIVE | Pattern.DOTALL);
            Matcher matcher = dayPattern.matcher(weekContent);
            
            if (matcher.find()) {
                dailyActivities.put(day, matcher.group(0).trim());
            }
        }
        
        return dailyActivities;
    }
}
