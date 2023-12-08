%Yi Nathen Qing
%BioE 217

clc; close all;
%clear all isnt really necessary here

figure.Position(3:4) = [600,1200];

%Import mp4 
vid = VideoReader('cellchase.mp4');

%Constants
t0 = 0;
tf = Inf;
vid.CurrentTime = t0;

%import first frame for target selection
frame = readFrame(vid);

%call minigui
prpt(frame, vid);

%prompt setup function
function prpt(frame, vid)

    %globals for later and t array to account for time
    xtotal = [];
    ytotal = [];
    t = linspace(0,vid.NumFrames-2,vid.NumFrames-1);

    %shows the thumbnail
    imshow(frame);
    
    %stands for target shape, like its a rectangle but still; choose target
    tshape = round(getPosition(imrect));
    
    clc;
        
    %make the target an actual matrix
    target = imcrop(frame, tshape);

    
    %flattening target outside loop cuz i dont got enough RAM
    target = im2gray(target);
    initT = target;
    sX = size(target, 2);
    sY = size(target, 1);

    cin = questdlg("Would you like to track this feature?");
    switch cin
        case 'Yes'
            while hasFrame(vid)
                %acquire new frame
                frame = readFrame(vid);
                %throw it into the equation to find most proximal guess and print
                target = Magic(target,frame);
                %pause for period
                pause(1/vid.FrameRate);
            end
            figure;
            %draw out total movement in xy and time
            plot3(xtotal,ytotal,t);
            xlabel('X');
            ylabel('Y');
            zlabel('T')
            title("movement overtime")

            %in case they say no, just reprompt
        case 'No'
            clc;
            prpt(frame, vid);
    end

    %NCC function takes the target and frame
    function result = Magic(target, frame)
    
        %flattening frame to 2d cuz easier to fit into normxcorr2
        frameE = im2gray(frame);
        
        %check for deviation against original target, if difference is too
        %large will do a histogram merge to even out the NCC score
        if(normxcorr2(initT, target) < 0.99)
            target = mix(target, initT);
        end
    
        %finding cross correlation between target and frame
        c = normxcorr2(target,frameE);
        
        %show frame
        imshow(frame);

        %find the max which is basically where it is most likely to be
        [yP, xP] = find(c == max(c(:)));
    
        %find center position of said area
        yD = yP - sY;
        xD = xP - sX;
    
        %record location
        ytotal(end+1) = xD(1); %yes its supposed to be like this to flip the graph
        xtotal(end+1) = yD(1);
    
        %form the rectangle
        shape = imrect(gca, [xD(1), yD(1), sX, sY]);
        
        %prep and pass matrix of updated target onto next loop
        dimension = floor(getPosition(shape));
        result = rgb2gray(imcrop(frame, dimension));
        
        
        %mixing function that performs histogram matching
        function blend = mix(A, B)
            % convert images to double
            A = im2double(A);
            B = im2double(B);
                
            %histogram matching
            blend = imhistmatch(A, B);
        end
    
    end
end


