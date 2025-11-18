trigger AccountTrigger on Account (before insert, after insert) {
    if(Trigger.isBefore && Trigger.isInsert) {
        for(Account acc : Trigger.new) {
            if(acc.AnnualRevenue == null) {
                acc.AnnualRevenue = 0;
            }
        }
    }
    
    if(Trigger.isAfter && Trigger.isInsert) {
        List<Task> tasks = new List<Task>();
        for(Account acc : Trigger.new) {
            Task t = new Task();
            t.Subject = 'Follow up on new account';
            t.WhatId = acc.Id;
            insert t;
        }
    }
}