package com.vjnt.util;

import com.vjnt.dao.StudentDAO;

/**
 * Test Phase Completion After FLN Filter
 * Verify that Phase 2 now shows 100% by excluding fln_completed = TRUE students
 */
public class TestPhaseCompletionAfterFix {
    
    public static void main(String[] args) {
        String udiseNo = "27150401803";
        
        //System.out.println("=== Test Phase Completion After Fix ===");
        //System.out.println("UDISE: " + udiseNo);
        //System.out.println("Testing with fln_completed filter enabled");
        //System.out.println("=========================================\n");
        
        StudentDAO studentDAO = new StudentDAO();
        
        //System.out.println("📊 Phase Completion Percentages:\n");
        
        // Test all 4 phases
        for (int phase = 1; phase <= 4; phase++) {
            int percentage = studentDAO.getPhaseCompletionPercentage(udiseNo, phase);
            boolean isComplete = studentDAO.isPhaseComplete(udiseNo, phase);
            
            String statusIcon = percentage == 100 ? "✓" : "⚠";
            String completeIcon = isComplete ? "✓ COMPLETE" : "✗ INCOMPLETE";
            
            //System.out.println(statusIcon + " Phase " + phase + ": " + percentage + "% - " + completeIcon);
        }
        
        //System.out.println("\n=========================================");
        
        // Check Phase 2 specifically
        int phase2Percentage = studentDAO.getPhaseCompletionPercentage(udiseNo, 2);
        
        if (phase2Percentage == 100) {
            //System.out.println("✓ SUCCESS! Phase 2 now shows 100% completion!");
            //System.out.println("  The fln_completed filter is working correctly.");
            //System.out.println("  Students with fln_completed = TRUE are excluded from calculation.");
        } else {
            //System.out.println("⚠ Phase 2 shows " + phase2Percentage + "% completion");
            //System.out.println("  Expected: 100%");
            //System.out.println("  This means there are still some students without Phase 2 assessment.");
        }
        
        //System.out.println("\n✓ Test Complete!");
    }
}
