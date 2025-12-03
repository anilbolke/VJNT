package com.vjnt.util;

import java.io.BufferedReader;
import java.io.FileReader;
import java.io.IOException;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

public class WeeklyActivityHTMLParser {
    
    /**
     * Parse HTML file and extract activities from table rows
     * @param filePath - Path to HTML file
     * @return Map of day number to activity text
     */
    public static Map<Integer, String> parseHTMLFile(String filePath) {
        Map<Integer, String> activities = new HashMap<>();
        
        try (BufferedReader reader = new BufferedReader(new FileReader(filePath))) {
            StringBuilder htmlContent = new StringBuilder();
            String line;
            
            while ((line = reader.readLine()) != null) {
                htmlContent.append(line).append("\n");
            }
            
            String html = htmlContent.toString();
            
            // Extract table rows
            Pattern trPattern = Pattern.compile("<tr>(.*?)</tr>", Pattern.DOTALL);
            Matcher trMatcher = trPattern.matcher(html);
            
            int dayCounter = 0;
            
            while (trMatcher.find()) {
                String trContent = trMatcher.group(1);
                
                // Skip header row
                if (trContent.contains("<th")) {
                    continue;
                }
                
                // Extract td elements
                List<String> tdContents = new ArrayList<>();
                Pattern tdPattern = Pattern.compile("<td[^>]*>(.*?)</td>", Pattern.DOTALL);
                Matcher tdMatcher = tdPattern.matcher(trContent);
                
                while (tdMatcher.find()) {
                    String tdContent = tdMatcher.group(1);
                    // Remove HTML tags and clean text
                    String cleanText = tdContent.replaceAll("<[^>]*>", "").trim();
                    tdContents.add(cleanText);
                }
                
                // We expect 3 columns: Day, Objective, Activity
                if (tdContents.size() >= 3) {
                    dayCounter++;
                    String day = tdContents.get(0);
                    String objective = tdContents.get(1);
                    String activity = tdContents.get(2);
                    
                    // Combine objective and activity
                    String combinedActivity = objective + " - " + activity;
                    activities.put(dayCounter, combinedActivity);
                }
            }
            
        } catch (IOException e) {
            e.printStackTrace();
        }
        
        return activities;
    }
    
    /**
     * Get activities for specific language and week
     * @param language - Language (Marathi/English)
     * @param weekNumber - Week number
     * @param webContentPath - Path to WebContent directory
     * @return Map of day number to activity text
     */
    public static Map<Integer, String> getActivitiesForWeek(String language, int weekNumber, String webContentPath) {
        String languageFolder = language.toUpperCase();
        String fileName = "WEEK " + weekNumber + ".html";
        String filePath = webContentPath + "\\" + languageFolder + "\\" + fileName;
        
        return parseHTMLFile(filePath);
    }
    
    /**
     * Get list of activity options formatted for dropdown
     * @param activities - Map of activities
     * @return List of formatted activity options
     */
    public static List<String> getActivityOptions(Map<Integer, String> activities) {
        List<String> options = new ArrayList<>();
        
        for (Map.Entry<Integer, String> entry : activities.entrySet()) {
            String option = "Day " + entry.getKey() + " - " + entry.getValue();
            options.add(option);
        }
        
        return options;
    }
}
