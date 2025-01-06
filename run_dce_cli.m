function run_dce_cli(subject_source_path, subject_tp_path)
    % Use full path to the subject timepoint as this function's argument.
    % Beware, try-catches are used to keep a batch script running.
    
    % Find and add subpaths 
    mfilepath=fileparts(which('run_dce_cli'));
    addpath(fullfile(mfilepath,'dce'));
    addpath(fullfile(mfilepath,'external_programs'));
    addpath(fullfile(mfilepath,'external_programs/niftitools'));
    addpath(fullfile(mfilepath,'parametric_scripts'));
    echo off;
    %% RUN A
    % load A prefs
    script_prefs = parse_preference_file('script_preferences.txt', 0, ...
        {'noise_pathpick' 'noise_pixsize' 'dynamic_files' ...
        'aif_files' 'roi_files' 't1map_files' 'noise_files' 'drift_files' ...
        'rootname' 'fileorder' 'quant' 'roimaskroi' 'aifmaskroi' 'aif_rr_type' ...
        'tr' 'fa' 'hematocrit' 'snr_filter' 'relaxivity' 'injection_time' ...
        'injection_duration' 'drift_global' 'blood_t1', 'start_t', 'end_t' ...
        'time_resolution' 'force_use_default_relaxivity'});
    
    % force 4D files
    filevolume = 1;
    % don't need to display pretty file list
    LUT = 1;

    % type casts
    noise_pathpick = str2num(script_prefs.noise_pathpick);
    noise_pixsize = str2num(script_prefs.noise_pixsize);
    
    % gather filenames
    tmp = dir(strcat(subject_tp_path, script_prefs.dynamic_files));
    dynamic_files = cellstr(strcat(tmp.folder, '/', tmp.name));
    
    tmp = dir(strcat(subject_tp_path, script_prefs.aif_files));
    aif_files = cellstr(strcat(tmp.folder, '/', tmp.name));
    
    tmp = dir(strcat(subject_tp_path, script_prefs.roi_files));
    roi_files = cellstr(strcat(tmp.folder, '/', tmp.name));
    
    tmp = dir(strcat(subject_tp_path, script_prefs.t1map_files));
    t1map_files = cellstr(strcat(tmp.folder, '/', tmp.name));

    if ~strcmp(script_prefs.noise_files,'')
        tmp = dir(strcat(subject_tp_path, script_prefs.dynamic_files));
        noise_files = cellstr(strcat(tmp.folder, '/', tmp.name));
    else
        noise_files = '';
    end

    if ~strcmp(script_prefs.drift_files,'')
        tmp = dir(strcat(subject_tp_path, script_prefs.dynamic_files));
        drift_files = cellstr(strcat(tmp.folder, '/', tmp.name));
    else
        drift_files = '';
    end

    quant = str2num(script_prefs.quant);
    roimaskroi = str2num(script_prefs.roimaskroi);
    aifmaskroi = str2num(script_prefs.aifmaskroi);
    time_resolution = str2double(script_prefs.time_resolution);
    relaxivity = str2double(script_prefs.relaxivity);
    force_use_default_relaxivity = str2double(script_prefs.force_use_default_relaxivity);
    filePattern = dir(strcat(subject_source_path,'/dce/*DCE.json'));
    dce_json = strcat(subject_source_path, '/dce/', filePattern.name);

    if exist(dce_json, 'file')
        disp("DCE JSON found.")
        fid = fopen(dce_json);
        raw = fread(fid,inf);
        str = char(raw');
        fclose(fid);
        json = jsondecode(str);

        if isfield(json, 'RepetitionTimeExcitation')
            tr = json.RepetitionTimeExcitation;
            time_resolution = json.RepetitionTime;
        elseif isfield(json, 'AcquisitionDuration')
            tr = json.RepetitionTime;
            time_resolution = json.AcquisitionDuration;
        elseif isfield(json, 'TriggerDelayTime')
            tr = json.RepetitionTime;
            n_reps = load_untouch_header_only(dynamic_files{1});
            n_reps = n_reps.dime.dim(5);
            time_resolution = json.TriggerDelayTime / n_reps / 1000;
        else
            tr = json.RepetitionTime;
        end

        if isfield(json, 'NumberOfAverages')
            time_resolution = time_resolution * json.NumberOfAverages;
        end

        if isfield(json, 'AcquisitionDateTime') && ~force_use_default_relaxivity
            date = json.AcquisitionDateTime;
            inputDateTime = datetime(date, 'InputFormat', 'yyyy-MM-dd''T''HH:mm:ss.SSSSSS');
            inputDate = dateshift(inputDateTime, 'start', 'day');
            contrastChangeDate = datetime('2017-10-01');
            if inputDate < contrastChangeDate
                % assume magnevist
                relaxivity = 3.8;
            elseif inputDate >= contrastChangeDate
                % assume dotarem
                relaxivity = 3.4;
            end
        end
        fa = json.FlipAngle;
    else
        tr = str2double(script_prefs.tr);
        fa = str2double(script_prefs.fa); 
    end
    B1_map = strcat(subject_tp_path, 'B1_scaled_dyn.nii.gz');
    if exist(B1_map, 'file')
        fa_matrix = load_untouch_nii(B1_map);
        true_fa = ones([size(fa_matrix.img) 1]);
        true_fa = fa_matrix.img * fa;
        fa = true_fa;
    end
    hematocrit = str2double(script_prefs.hematocrit);
    snr_filter = str2num(script_prefs.snr_filter);
    injection_time = str2num(script_prefs.injection_time);
    drift_global = str2num(script_prefs.drift_global);
    blood_t1 = str2num(script_prefs.blood_t1);
    injection_duration = str2num(script_prefs.injection_duration);
    start_t = str2num(script_prefs.start_t);
    end_t = str2num(script_prefs.end_t);

    % convert tr to ms
    tr = tr * 1000;

    % main function call
    while true
        try
            [A_results, A_vars, errormsg] = A_make_R1maps_func(filevolume, noise_pathpick, ...
                noise_pixsize, LUT, dynamic_files,aif_files, ...
                roi_files, t1map_files, ...
                noise_files, drift_files, ...
                script_prefs.rootname, script_prefs.fileorder, quant, roimaskroi, ...
                aifmaskroi, script_prefs.aif_rr_type, tr, fa, hematocrit, snr_filter, ...
                relaxivity, injection_time, drift_global, blood_t1, injection_duration, ...
                start_t, end_t, false);
            break;
        catch L
            if strcmp(L.identifier,'A_make_R1maps_func:AIFVoxelsRemoved')
                disp(L)
                disp('Trying again by retaining 1 more baseline slice...')
                % must chop off at least 1 frame due to severe frame 1 artifacts
                if start_t > 2
                    start_t = start_t - 1;
                else
                    disp('Not enough baseline acquisitions.')
                    return;
                end
            else
                return;
            end
        end
    end

    if ~isempty(errormsg)
        error(errormsg);
        return;
    end

    %% RUNB
    % load B prefs
    script_prefs = parse_preference_file('script_preferences.txt', 0, ...
        {'start_time', 'end_time', 'auto_find_injection', 'start_injection', ...
        'end_injection', 'fit_aif', 'time_resolution', 'aif_type', ...
        'import_aif_path', 'timevectyn', 'timevectpath', 'rootname', ...
        'fileorder', 'aif_rr_type'});

    % type casts
    start_time = str2num(script_prefs.start_time);
    end_time = str2num(script_prefs.end_time);
    auto_find_injection = str2num(script_prefs.auto_find_injection);
    start_injection = str2num(script_prefs.start_injection);
    end_injection = str2num(script_prefs.end_injection);
    aif_type = str2num(script_prefs.aif_type);
    import_aif_path = script_prefs.import_aif_path;
    timevectyn = str2num(script_prefs.timevectyn);
    timevectpath = script_prefs.timevectpath;

    % convert time resolution into minutes
    time_resolution = time_resolution / 60;

    fit_aif = aif_type;
    if (auto_find_injection)
        start_injection = -1;
        end_injection = -1;
    end

    % main function call
    fail = 0;
    while (fail < 3)
        try
            [B_results, B_vars] = B_AIF_fitting_func(A_results, A_vars, ...
                start_time, end_time, start_injection, ...
                end_injection, fit_aif, import_aif_path, ...
                time_resolution, timevectpath, false);
            break;
        catch L
            disp("RUNB failed. Repeating in case of bad read...")
            disp(L.message)
            if strcmp(L.message, "Index exceeds the number of array elements. Index must not exceed 0.")
                start_t = start_t - 1;
                [A_results, A_vars, errormsg] = A_make_R1maps_func(filevolume, noise_pathpick, ...
                noise_pixsize, LUT, dynamic_files, aif_files, ...
                roi_files, t1map_files, noise_files, drift_files, ...
                script_prefs.rootname, script_prefs.fileorder, quant, roimaskroi, ...
                aifmaskroi, script_prefs.aif_rr_type, tr, fa, hematocrit, snr_filter, ...
                relaxivity, injection_time, drift_global, blood_t1, injection_duration, ...
                start_t, end_t, false);
            end
        end
        fail = fail + 1;
    end
    if fail >= 3
        warning("RUNB failed and could not recover.")
        return;
    end
    %% RUND
    script_prefs = parse_preference_file('script_preferences.txt', 0, ...
        {'tofts', 'ex_tofts', 'fxr', 'auc', 'nested', 'patlak', ...
        'tissue_uptake', 'two_cxm', 'FXL_rr', 'time_smoothing', ...
        'time_smoothing_window', 'xy_smooth_size', 'number_cpus', 'roi_list', ...
        'fit_voxels', 'outputft'});

    % type casts
    dce_model.tofts = str2num(script_prefs.tofts);
    dce_model.ex_tofts = str2num(script_prefs.ex_tofts);
    dce_model.fxr = str2num(script_prefs.fxr);
    dce_model.auc = str2num(script_prefs.auc);
    dce_model.nested = str2num(script_prefs.nested);
    dce_model.patlak = str2num(script_prefs.patlak);
    dce_model.tissue_uptake = str2num(script_prefs.tissue_uptake);
    dce_model.two_cxm = str2num(script_prefs.two_cxm);
    dce_model.FXL_rr = str2num(script_prefs.FXL_rr);
    dce_model.fractal = 0;

    time_smoothing_window = str2num(script_prefs.time_smoothing_window);
    xy_smooth_size = str2num(script_prefs.xy_smooth_size);
    number_cpus = str2num(script_prefs.number_cpus);
    fit_voxels = str2num(script_prefs.fit_voxels);
    outputft = str2num(script_prefs.outputft);

    if (~isempty(script_prefs.roi_list))
        roi_list = split(script_prefs.roi_list);
    else
        roi_list = '';
    end

    neuroecon = 0;

    % main function call
    try
        D_results = D_fit_voxels_func(B_results, B_vars, dce_model, ...
            script_prefs.time_smoothing,time_smoothing_window, ...
            xy_smooth_size,number_cpus,roi_list,fit_voxels,neuroecon, ...
            outputft, false);
    catch L
        disp("RUND failed, probably due to a REALLY dumb error:")
        disp(L.message)
    end
    % fig to png
    cd(subject_tp_path);
    fig = openfig('dce/dceAIF_fitting.fig');
    filename = 'dce/dceAIF_fitting.png';
    saveas(fig, filename);

    fig = openfig('dce/dce_timecurves.fig');
    filename = 'dce/dce_timecurves.png';
    saveas(fig, filename);

    %% clean up
    close all
