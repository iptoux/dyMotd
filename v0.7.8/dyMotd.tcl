#!/usr/bin/env tclsh
# MOTD script original? / mod mewbies.com
# Edited/Rewrite by iptoux / iptoux@lavabit.com
# 
#   @CHANGELOG
#
#   * 19.08.2012 - v0.7.8
#       + added dynamic display "state of services" too root (you can set it in config file)
#       + added display of dynamic statement (loaded from config file)
#       + ending rewrite of code
#
#   * 18.08.2012 - v0.7.2
#       + added dynamic config settings in external config file
#       + begin full rewrite of script
#       + added displaying state of services 
#
#   * 17.08.2012 - v0.6.5
#       + edited header
#       + added/edited colors
#       + added ssh failed logins
#       + added dynamic user mode
#
#   * 16.08.2012 - v0.5.0 (original v1.0 by author)
#       + downloaded script
#       + check script
#       - remove not used variables
#       + first tunings
#
#   @TODO
#       + add dynamic header (hostname)  
#       + add install script
#       + display count of new mails (only local)
#       + setting colors in config file
#
# * END *


# * ScriptMainVars *
set config(dir) "/etc/srvtls/motd"
set config(file) $config(dir)/.config

set var(user) $env(USER)
set var(path) $env(PWD)
set var(home) $env(HOME)

# * Checking config file
if {[file exists $config(file)]&&[file readable $config(file)]} {
    source $config(file)
} else {
    puts ""
    puts "\[MOTD\] -> Config not Found, please check your settings:"
    puts "\[MOTD\] -> ConfigDir: $config(dir)"
    puts "\[MOTD\] -> ConfigFile (Full): $config(file)"
    puts ""
    return 0
}


set config(file_stm) $config(dir)/$config(file_statement)

# * Only show in /home/$user ?
if { $config(display_only_home) == 1 && $var(user) != "root"} {
    if {![string match -nocase "/home*" $var(path)] && ![string match -nocase "/usr/home*" $var(path)] } {
        return 0
    }
}


# * Load default variables to display *

# * Calculate last login
set lastlog [exec -- lastlog -u $var(user)]
set ll(1)  [lindex $lastlog 7]
set ll(2)  [lindex $lastlog 8]
set ll(3)  [lindex $lastlog 9]
set ll(4)  [lindex $lastlog 10]
set ll(5)  [lindex $lastlog 6]

# * Calculate current system uptime
set uptime    [exec -- /usr/bin/cut -d. -f1 /proc/uptime]
set up(days)  [expr {$uptime/60/60/24}]
set up(hours) [expr {$uptime/60/60%24}]
set up(mins)  [expr {$uptime/60%60}]
set up(secs)  [expr {$uptime%60}]

# * Calculate usage of home directory
set usage [lindex [exec -- /usr/bin/du -ms $var(home)] 0]

# * Calculate SSH logins:
set logins     [exec users]
set log(c)  [llength $logins]

if { $var(user) == "root" && $config(display_failed_logins) == 1 } {
	set failures    [lindex [exec -- grep sshd /var/log/auth.log | awk /failure/ | wc -l] 0]
}

# * Calculate processes
set psu [lindex [exec -- ps U $var(user) h | wc -l] 0]
set psa [lindex [exec -- ps -A h | wc -l] 0]

# * Calculate current system load
set loadavg     [exec -- /bin/cat /proc/loadavg]
set sysload(1)  [lindex $loadavg 0]
set sysload(5)  [lindex $loadavg 1]
set sysload(15) [lindex $loadavg 2]

# * Calculate Memory
set memory  [exec -- free -m]
set mem(t)  [lindex $memory 7]
set mem(u)  [lindex $memory 8]
set mem(f)  [lindex $memory 9]
set mem(c)  [lindex $memory 16]
set mem(s)  [lindex $memory 19]

# * The Statement/Services *
# * Please do not edit here!! This is realy complicated and big mass of code.
# * Only edit this code if you know what you do!

# * Is user == user and is statement dynamic?
if { $var(user) != "root" && $config(variable_statements) == 1 } {
    
    set statement(title) "\033\[01;32m ::::::::::::::::::::::::::::::::-STATEMENT-::::::::::::::::::::::::::::::::\033\[0m"
    
    if {[file exists $config(file_stm)]&&[file readable $config(file_stm)]} {
        set fp [open $config(file_stm)]
        set i 0
            while {-1!=[gets $fp line]} {
                incr i 1
                set statement(line$i) $line
            }
        close $fp
    } else {
        # * statement file not found using default statement.
        set statement(line1) $config(statement_line1)
        set statement(line2) $config(statement_line2)
        
    }
    
    
}


# * Is user == root and display state of services enabled?
if { $var(user) == "root" && $config(display_services) == 1 } {

set stof_l1 ""
set stof_l2 ""

set statement(title) "\033\[01;32m ::::::::::::::::::::::::::::::::-SERVICES-::::::::::::::::::::::::::::::::\033\[0m"

foreach {name service} [array get services_line_1] {
   if {[catch {exec -- pgrep $service}] == 0 || [lindex $::errorCode 0] == "NONE" } {
    append stof_l1 "$name: \033\[07m OK \033\[0m - "
   } else {
    append stof_l1 "$name: \033\[05m FAIL \033\[0m - "
   }
}

foreach {name2 service2} [array get services_line_2] {
   if {[catch {exec -- pgrep $service2}] == 0 || [lindex $::errorCode 0] == "NONE" } {
    append stof_l2 "$name2: \033\[07m OK \033\[0m - "
   } else {
    append stof_l2 "$name2: \033\[05m FAIL \033\[0m - "
   }
}

# * Remove ending - of each line
set stof_l1 [string range $stof_l1 0 [expr [string length $stof_l1] - 3]]
set stof_l2 [string range $stof_l2 0 [expr [string length $stof_l2] - 3]]

# * Center each line 
set stof_count_whitespace_l1 [expr $config(maxstringlenght) - [string length $stof_l1]]
set stof_count_whitespace_l1 [expr $stof_count_whitespace_l1 / 2]
set stof_count_whitespace_l2 [expr $config(maxstringlenght) - [string length $stof_l2]]
set stof_count_whitespace_l2 [expr $stof_count_whitespace_l2 / 2 - 4]

set wl1 ""
set wl2 ""
set il1 0
set il2 0

while {$il1 < $stof_count_whitespace_l1} {
    append wl1 " "
    set il1 [expr {$il1 + 1}]
}

while {$il2 < $stof_count_whitespace_l2} {
    append wl2 " "
    set il2 [expr {$il2 + 1}]
}

set tl1 [string index $stof_l1 0]
set tl2 [string index $stof_l2 0]

set stof_l1 [string replace $stof_l1 0 0 $wl1$tl1]
set stof_l2 [string replace $stof_l2 0 0 $wl2$tl2]

} elseif { $var(user) == "root" } {
    set statement(title) "\033\[01;32m ::::::::::::::::::::::::::::::::-SERVICES-::::::::::::::::::::::::::::::::\033\[0m"
}



# * Output *
puts "\033\[01;32m$config(head)\033\[0m"
puts "  \033\[01;34mWelcome back $var(user)!\033\[0m"
puts "  \033\[01;31mLast Login....:\033\[0m $ll(1) $ll(2) $ll(3) $ll(4) from $ll(5)"
puts "  \033\[01;31mUptime........:\033\[0m $up(days)days $up(hours)hours $up(mins)minutes $up(secs)seconds"
puts "  \033\[01;31mLoad..........:\033\[0m $sysload(1) (1minute) $sysload(5) (5minutes) $sysload(15) (15minutes)"
puts "  \033\[01;31mMemory MB.....:\033\[0m $mem(t)  Used: $mem(u)  Free: $mem(f)  Free Cached: $mem(c)  Swap In Use: $mem(s)"
puts "  \033\[01;31mDisk Usage....:\033\[0m You're using ${usage}MB in $var(home)"
puts "  \033\[01;31mSSH Logins....:\033\[0m There are currently \033\[07m $log(c) \033\[0m users logged in."
if { $var(user) == "root" } {
	puts "  \033\[01;31mSSH Failed....:\033\[0m There have been \033\[05m ${failures} \033\[0m failed attempts this week."
}
puts "  \033\[01;31mProcesses.....:\033\[0m You're running ${psu} which makes a total of ${psa} running"
puts ""
if { $var(user) == "root" && $config(display_services) == 1 } {
    puts "$statement(title)"
    puts "$stof_l1"
    puts "$stof_l2"
} elseif { $var(user) == "root" } {
    puts "$statement(title)"
    puts "\033\[01;31mDisplaying the state of services is disabled, please check your config\033\[0m"
} else {
    puts "$statement(title)"
    puts "$statement(line1)"
    puts "$statement(line2)"
}
