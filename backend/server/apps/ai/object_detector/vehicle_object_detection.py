import argparse
from datetime import date
import json
import math

import os
# limit the number of cpus used by high performance libraries
os.environ["OMP_NUM_THREADS"] = "1"
os.environ["OPENBLAS_NUM_THREADS"] = "1"
os.environ["MKL_NUM_THREADS"] = "1"
os.environ["VECLIB_MAXIMUM_THREADS"] = "1"
os.environ["NUMEXPR_NUM_THREADS"] = "1"

import sys
import numpy as np
from pathlib import Path
import torch
import torch.backends.cudnn as cudnn

FILE = Path(__file__).resolve()
ROOT = FILE.parents[0]  # yolov5 strongsort root directory
WEIGHTS = ROOT / 'weights'


if str(ROOT) not in sys.path:
    sys.path.append(str(ROOT))  # add ROOT to PATH
if str(ROOT / 'yolov5') not in sys.path:
    sys.path.append(str(ROOT / 'yolov5'))  # add yolov5 ROOT to PATH
if str(ROOT / 'trackers' / 'strong_sort') not in sys.path:
    sys.path.append(str(ROOT / 'trackers' / 'strong_sort'))  # add strong_sort ROOT to PATH

ROOT = Path(os.path.relpath(ROOT, Path.cwd()))  # relative
import logging
from yolov5.models.common import DetectMultiBackend
from yolov5.utils.dataloaders import VID_FORMATS, LoadImages, LoadStreams
from yolov5.utils.general import (LOGGER, check_img_size, non_max_suppression, scale_coords, check_requirements,cv2, check_imshow, xyxy2xywh, increment_path, strip_optimizer, colorstr, print_args, check_file)
from yolov5.utils.torch_utils import select_device, time_sync
from yolov5.utils.plots import Annotator, colors, save_one_box
from trackers.multi_tracker_zoo import create_tracker

# remove duplicated stream handler to avoid duplicated logging
logging.getLogger().removeHandler(logging.getLogger().handlers[0])

def find(lst, key1, value1, key2, value2):
    for i, dic in enumerate(lst):
        if dic[key1] == value1 and dic[key2] == value2:
            return i
    return -1


class VehicleObjectDetection:
    @torch.no_grad()
    def __init__(self, 
                yolo_weights=WEIGHTS / 'best.pt',  
                reid_weights=WEIGHTS / 'osnet_x0_25_msmt17.pt',
                name=date.today().strftime("%d-%m-%Y"),
                project= ROOT.parents[2].absolute() / 'runs/track',
                save_txt=True,
                exist_ok=False,
                device='0'):

        # Directories
        if not isinstance(yolo_weights, list):  # single yolo model
            exp_name = yolo_weights.stem
        elif type(yolo_weights) is list and len(yolo_weights) == 1:  # single models after --yolo_weights
            exp_name = Path(yolo_weights[0]).stem
        else:  # multiple models after --yolo_weights
            exp_name = 'ensemble'
        exp_name = name if name else exp_name + "_" + reid_weights.stem

        if(not (Path(project)/exp_name).exists()):
            self.save_dir = increment_path(Path(project) / exp_name, exist_ok=True, mkdir=True)
            (self.save_dir / 'tracks' if save_txt else self.save_dir).mkdir(parents=True, exist_ok=True)  # make dir
            (self.save_dir / "status").mkdir(parents=True, exist_ok=True) 
        else:
            self.save_dir = Path(project)/exp_name
 
    
        # Load model
        self.device = select_device(device)
        self.model = DetectMultiBackend(yolo_weights, device=self.device, dnn=False, data=None, fp16=False)
        
               
    @torch.no_grad()
    def predict(
            self,
            task_id: str,
            time,
            source="./Pexels Videos 1192116.mp4",
            tracking_method='strongsort',
            reid_weights=WEIGHTS / 'osnet_x0_25_msmt17.pt',
            imgsz=(640, 640),  # inference size (height, width)
            conf_thres=0.25,  # confidence threshold
            iou_thres=0.45,  # NMS IOU threshold
            max_det=1000,  # maximum detections per image
            show_vid=False,  # show results
            save_txt=True,  # save results to *.txt
            save_vid=True,  # save confidences in --save-txt labels
            classes=None,  # filter by class: --class 0, or --class 0 2 3
            agnostic_nms=False,  # class-agnostic NMS
            augment=False,  # augmented inference
            visualize=False,  # visualize features
            line_thickness=2,  # bounding box thickness (pixels)
            hide_labels=False,  # hide labels
            hide_conf=False,  # hide confidences
            hide_class=False,  # hide IDs
            half=False,  # use FP16 half-precision inference
        ):  

        source = str(source)
        

        stride, names, pt = self.model.stride, self.model.names, self.model.pt
        imgsz = check_img_size(imgsz, s=stride) 
        dataset = LoadImages(source, img_size=imgsz, stride=stride, auto=pt)
        nr_sources = 1
        vid_path, vid_writer, txt_path = [None] * nr_sources, [None] * nr_sources, [None] * nr_sources

        #Find fps
        video = cv2.VideoCapture(source)

        # Find OpenCV version
        (major_ver, minor_ver, subminor_ver) = (cv2.__version__).split('.')

        # With webcam get(CV_CAP_PROP_FPS) does not work.
        # Let's see for ourselves.

        if int(major_ver)  < 3 :
            fps = video.get(cv2.cv.CV_CAP_PROP_FPS)
            length = int(video.get(cv2.cv.CAP_PROP_FRAME_COUNT))
        else :
            fps = video.get(cv2.CAP_PROP_FPS)
            length = int(video.get(cv2.CAP_PROP_FRAME_COUNT)) 

        # Create as many strong sort instances as there are video sources
        tracker_list = []
        tracking_results = []
        for i in range(nr_sources):
            tracker = create_tracker(tracking_method, reid_weights, self.device, half)
            tracker_list.append(tracker, )
            if hasattr(tracker_list[i], 'model'):
                if hasattr(tracker_list[i].model, 'warmup'):
                    tracker_list[i].model.warmup()
        outputs = [None] * nr_sources

        # Run tracking
        #model.warmup(imgsz=(1 if pt else nr_sources, 3, *imgsz))  # warmup
        dt, seen = [0.0, 0.0, 0.0, 0.0], 0
        curr_frames, prev_frames = [None] * nr_sources, [None] * nr_sources
        for frame_idx, (path, im, im0s, vid_cap, s) in enumerate(dataset):
            t1 = time_sync()
            im = torch.from_numpy(im).to(self.device)
            im = im.half() if half else im.float()  # uint8 to fp16/32
            im /= 255.0  # 0 - 255 to 0.0 - 1.0
            if len(im.shape) == 3:
                im = im[None]  # expand for batch dim
            t2 = time_sync()
            dt[0] += t2 - t1

            # Inference
            visualize = increment_path(self.save_dir / Path(path[0]).stem, mkdir=True) if visualize else False
            pred = self.model(im, augment=augment, visualize=visualize)
            t3 = time_sync()
            dt[1] += t3 - t2

            # Apply NMS
            pred = non_max_suppression(pred, conf_thres, iou_thres, classes, agnostic_nms, max_det=max_det)
            dt[2] += time_sync() - t3

            # Process detections
            for i, det in enumerate(pred):  # detections per image
                seen += 1
                p, im0, _ = path, im0s.copy(), getattr(dataset, 'frame', 0)
                p = Path(p)  # to Path
                # video file
                if source.endswith(VID_FORMATS):
                    txt_file_name = p.stem
                    save_path = str(self.save_dir / p.name)  # im.jpg, vid.mp4, ...
                # folder with imgs
                else:
                    txt_file_name = p.parent.name  # get folder name containing current img
                    save_path = str(self.save_dir / p.parent.name)  # im.jpg, vid.mp4, ...
                curr_frames[i] = im0

                txt_path = str(self.save_dir / 'tracks' / task_id)  # im.txt
                s += '%gx%g ' % im.shape[2:]  # print string

                annotator = Annotator(im0, line_width=line_thickness, pil=not ascii)

                if hasattr(tracker_list[i], 'tracker') and hasattr(tracker_list[i].tracker, 'camera_update'):
                    if prev_frames[i] is not None and curr_frames[i] is not None:  # camera motion compensation
                        tracker_list[i].tracker.camera_update(prev_frames[i], curr_frames[i])

                if det is not None and len(det):
                    # Rescale boxes from img_size to im0 size
                    det[:, :4] = scale_coords(im.shape[2:], det[:, :4], im0.shape).round()  # xyxy

                    # Print results
                    for c in det[:, -1].unique():
                        n = (det[:, -1] == c).sum()  # detections per class
                        s += f"{n} {names[int(c)]}{'s' * (n > 1)}, "  # add to string

                    # pass detections to strongsort
                    t4 = time_sync()
                    outputs[i] = tracker_list[i].update(det.cpu(), im0)
                    t5 = time_sync()
                    dt[3] += t5 - t4

                    # draw boxes for visualization
                    if len(outputs[i]) > 0:
                        for j, (output, conf) in enumerate(zip(outputs[i], det[:, 4])):
                        
                            bboxes = output[0:4]
                            id = output[4]
                            cls = output[5]

                            if save_txt:
                                # to MOT format
                                #bbox_left = output[0]
                                #bbox_top = output[1]
                                #bbox_w = output[2] - output[0]
                                #bbox_h = output[3] - output[1]
                                c = int(c)
                                tracking_results.append({"id": id, "time_of_capture":  frame_idx/fps, "type_of_vehicle": names[c]})

                            if save_vid  or show_vid:  # Add bbox to image
                                c = int(cls)  # integer class
                                id = int(id)  # integer id
                                label = None if hide_labels else (f'{id} {names[c]}' if hide_conf else \
                                    (f'{id} {conf:.2f}' if hide_class else f'{id} {names[c]} {conf:.2f}'))
                                annotator.box_label(bboxes, label, color=colors(c, True))

                    LOGGER.info(f'{s}Done. yolo:({t3 - t2:.3f}s), {tracking_method}:({t5 - t4:.3f}s)')

                else:
                    #strongsort_list[i].increment_ages()
                    LOGGER.info('No detections')

                # Stream results
                im0 = annotator.result()
                if show_vid:
                    cv2.imshow(str(p), im0)
                    cv2.waitKey(1)  # 1 millisecond

                # Save results (image with detections)
                if save_vid:
                    if vid_path[i] != save_path:  # new video
                        vid_path[i] = save_path
                        if isinstance(vid_writer[i], cv2.VideoWriter):
                            vid_writer[i].release()  # release previous video writer
                        if vid_cap:  # video
                            fps = vid_cap.get(cv2.CAP_PROP_FPS)
                            w = int(vid_cap.get(cv2.CAP_PROP_FRAME_WIDTH))
                            h = int(vid_cap.get(cv2.CAP_PROP_FRAME_HEIGHT))
                        else:  # stream
                            fps, w, h = 30, im0.shape[1], im0.shape[0]
                        save_path = str(Path(save_path).with_suffix('.mp4'))  # force *.mp4 suffix on results videos
                        vid_writer[i] = cv2.VideoWriter(save_path, cv2.VideoWriter_fourcc(*'mp4v'), fps, (w, h))
                    vid_writer[i].write(im0)

                prev_frames[i] = curr_frames[i]

                if((math.floor((frame_idx/length)*100)) % 25 == 0):
                    with open(str(self.save_dir) + "/status/" + task_id + ".json", "w") as f:
                        f.write(json.dumps({"id":task_id, "status": frame_idx/length, "received_time": time}))
                
        jsonList =  [] 
        for registry in tracking_results:
            if not any(dictionary['id'] == registry["id"] and dictionary["type_of_vehicle"] == registry["type_of_vehicle"] for dictionary in jsonList):
                registry["inital_time_of_capture"] = registry["time_of_capture"]
                registry["final_time_of_capture"] = 0
                registry.pop("time_of_capture")
                jsonList.append(registry)
            else:
                idx = find(jsonList, "id", registry["id"], "type_of_vehicle", registry["type_of_vehicle"])
                if registry["time_of_capture"] > jsonList[idx]["inital_time_of_capture"] and registry["time_of_capture"] > jsonList[idx]["final_time_of_capture"]:
                    jsonList[idx]["final_time_of_capture"]  = registry["time_of_capture"]
                elif registry["time_of_capture"] < jsonList[idx]["inital_time_of_capture"]:
                    jsonList[idx]["inital_time_of_capture"]  = registry["time_of_capture"]


        for registry in jsonList:
            if registry["final_time_of_capture"] == 0:
                jsonList.remove(registry)

        with open(txt_path + '.json', 'w+') as f:
            f.write(json.dumps(jsonList))

        with open(str(self.save_dir) + "/status/" + task_id + ".json", "w") as f:

            f.write(json.dumps({
                "id": task_id, 
                "status": "COMPLETED", 
                "received_time": time
                }))
        cv2.destroyAllWindows()
        

        # Print results
        t = tuple(x / seen * 1E3 for x in dt)  # speeds per image
        LOGGER.info(f'Speed: %.1fms pre-process, %.1fms inference, %.1fms NMS, %.1fms {tracking_method} update per image at shape {(1, 3, *imgsz)}' % t)
        
