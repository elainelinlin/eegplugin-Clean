function vers = eegplugin_dup15q(fig, trystrs, catchstrs)

    vers = 'dup15q.1';
    if nargin < 3
        error('eegplugin_dup15q requires 3 arguments');
    end
    
    % Add folder to path
    % -------------------
    
    % Find tools menu
    % ----------------
    menu = findobj(fig, 'tag', 'tools');

    % menu callback commands
    % ----------------------
    comchangeTag        = [ trystrs.check_event '[EEG LASTCOM] = pop_changeTag(EEG);' catchstrs.new_and_hist ];
    comcleaningScript   = [ trystrs.check_epoch '[EEG LASTCOM] = pop_cleaningScript(EEG);' catchstrs.new_and_hist ];
    comcalculatePower   = [ trystrs.check_epoch '[studyPowerVals LASTCOM] = pop_calculatePower(EEG);' catchstrs.add_to_hist ];
    comEZtopo           = [ trystrs.no_check 'pop_eztopo();' catchstrs.add_to_hist ]; 
    comchangeSingleTag  = [ trystrs.check_event '[EEG LASTCOM] = pop_changeSingleTag(EEG);' catchstrs.new_and_hist ];
    
    
    % create menus
    % ------------
    submenu = uimenu( menu, 'Label', 'Ich Heisse Joel', 'separator', 'on');
    uimenu( submenu, 'Label', 'Delete bad or out of range qEEG tags', 'CallBack', comchangeTag);
    uimenu( submenu, 'Label', 'Interpolate bad chegments or delete bad segments/channels', 'CallBack', comcleaningScript);
    uimenu( submenu, 'Label', 'Calculate power values', 'CallBack', comcalculatePower);
    uimenu( submenu, 'Label', 'Plot EZ Topography', 'CallBack', comEZtopo);
    uimenu( submenu, 'Label', 'Change a single tag', 'CallBack', comchangeSingleTag, 'separator', 'on');
   