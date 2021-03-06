function [filenames_all_conditions] = results_tracking_V4(dt,conv, filenames_this_condition)

        for m = 1:length(filenames_this_condition)
            filename = filenames_this_condition{m}
            % import csv using this amazing importer
            if filename == "Cell_placeholder"
                continue
            end
            [Trajectory, Frame, x, y, z] = csvimport(filename , 'columns', {'Trajectory', 'Frame', 'x', 'y', 'z'} ) ;

            idx = find(diff(Trajectory) > 0);
            if isempty(idx)
                continue
            end

            S = [];
            for i = 1:length(idx)
                if i < 10
                    S = [S;strcat('part0000',num2str(i))];
                elseif i >= 10 && i < 100
                    S = [S;strcat('part000',num2str(i))];
                elseif i >= 100 && i < 999
                    S = [S;strcat('part00',num2str(i))];
                elseif i >=1000 && i < 9999
                    S = [S;strcat('part0',num2str(i))];
                elseif i >= 10000 && i < 99999
                    S = [S;strcat('part',num2str(i))];
                end
            end

            field = cellstr(S);

            result = cell2struct(field','tracking',1);

            MSD = zeros(1,length(idx));
            time = zeros(1,length(idx));
            x_res = zeros(1,length(idx));
            y_res = zeros(1,length(idx));
            frame_res = zeros(1,length(idx));

            for i = 1:length(idx)

                if i == 1
                    x_res(1:idx(i),i) = x(1:idx(i));
                    y_res(1:idx(i),i) = y(1:idx(i));
                    frame_res(1:idx(i),i) = Frame(1:idx(i));
                    time(1:idx(i),i) = 0:dt:dt*(idx(i)-1);
                    MSD(1:idx(i),i) = calculate_MSD(x(1:idx(i)),y(1:idx(i)),0,dt,conv);

                elseif i > 1
                    x_res(1:(idx(i)-idx(i-1)),i) = x((idx(i-1)+1):idx(i));
                    y_res(1:(idx(i)-idx(i-1)),i) = y((idx(i-1)+1):idx(i));
                    frame_res(1:(idx(i)-idx(i-1)),i) = Frame((idx(i-1)+1):idx(i));
                    time(1:(idx(i)-idx(i-1)),i) = 0:dt:dt*(idx(i)-idx(i-1)-1);
                    MSD(1:(idx(i)-idx(i-1)),i) = calculate_MSD(x((idx(i-1)+1):idx(i)),y((idx(i-1)+1):idx(i)),0,dt,conv);

                end 

                result(i).tracking = struct('time',time(find(MSD(:,i))>0,i),...
                    'x',x_res(find(MSD(:,i))>0,i),...
                    'y',y_res(find(MSD(:,i))>0,i),...
                    'MSD',MSD(find(MSD(:,i))>0,i),...
                    'frame',frame_res(find(MSD(:,i))>0,i));


            end

            filename_int = filenames_this_condition{m};
            name_file = filename_int(1:strfind(filename_int,'.csv')-1);

            saving_name = strcat('tracked_',name_file,'.mat');
            save(saving_name,'result')

        end
        %% 
    

    % uisave('result')
    % save P=8_bis.mat result 

    end




