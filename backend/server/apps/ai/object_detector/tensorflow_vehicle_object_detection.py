
from mimetypes import init
import os
os.add_dll_directory("C:/Program Files/NVIDIA GPU Computing Toolkit/CUDA/v11.7/bin")
os.add_dll_directory("C:\Program Files\ZLIB\dll_x64")
os.environ['TF_CPP_MIN_LOG_LEVEL'] = '3'  # or any {'0', '1', '2'}
import time
import numpy as np
import tensorflow as tf
from matplotlib import pyplot as plt
from PIL import Image
import cv2 as cv2
from object_detection.utils import label_map_util
from object_detection.utils import visualization_utils as viz_utils


FILE_OUTPUT = '../output.avi'
PATH_TO_SAVED_MODEL = "../AI Model/my_model_faster_rcnn_nt_inception" + "/saved_model"
PATH_TO_LABELS = "../AI Model/label_map.pbtxt"


# Checks and deletes the output file
# You cant have a existing file or it will through an error
if os.path.isfile(FILE_OUTPUT):
    os.remove(FILE_OUTPUT)


#def load_image_into_numpy_array(path):
#    """Load an image from file into a numpy array.
#
#    Puts image into numpy array to feed into tensorflow graph.
#    Note that by convention we put it into a numpy array with shape
#    (height, width, channels), where channels=3 for RGB.
#
#    Args:
#      path: the file path to the image
#
#    Returns:
#      uint8 numpy array with shape (img_height, img_width, 3)
#    """
#    return np.array(Image.open(path))


class VehicleObjectDetection:
    def __init__(self):
        # Load saved model and build the detection function
        self.model = tf.saved_model.load(PATH_TO_SAVED_MODEL)
        self.detect_fn = self.model.signatures["serving_default"]
        self.category_index = label_map_util.create_category_index_from_labelmap(
            PATH_TO_LABELS, use_display_name=True
        )
        self.starting_frame = 0
        print("it loaded")

    def predict(self, file=None):
        print("It started")
        # Playing video from file
        cap = cv2.VideoCapture(file)
        frame_amount = int(cap.get(cv2.CAP_PROP_FRAME_COUNT))
        # Default resolutions of the frame are obtained.The default resolutions are system dependent.
        # We convert the resolutions from float to integer.
        frame_width = int(cap.get(3))
        frame_height = int(cap.get(4))

        # Define the codec and create VideoWriter object.The output is stored in 'output.avi' file.
        out = cv2.VideoWriter(FILE_OUTPUT, cv2.VideoWriter_fourcc('M', 'J', 'P', 'G'),
                              10, (frame_width, frame_height))

        while(cap.isOpened()):
            # Capture frame-by-frame
            ret, frame = cap.read()
            if ret == True:
                # Expand dimensions since the model expects images to have shape: [1, None, None, 3]
                image_np_expanded = np.expand_dims(frame, axis=0)
                #image_np = load_image_into_numpy_array(frame)
                #input_tensor = tf.convert_to_tensor(image_np_expanded)
                #input_tensor = image_np_expanded[tf.newaxis, ...]
                detections = self.detect_fn(input_tensor =image_np_expanded)
                num_detections = int(detections.pop("num_detections"))
                detections = {
                    key: value[0, :num_detections].numpy() for key, value in detections.items()
                }
                detections["num_detections"] = num_detections

                # detection_classes should be ints.
                detections["detection_classes"] = detections["detection_classes"].astype(np.int64)

                # Actual detection.
                #(boxes, scores, classes, num) = sess.run(
                #    [detection_boxes, detection_scores, detection_classes, num_detections],
                #    feed_dict={image_tensor: image_np_expanded})
                # Visualization of the results of a detection.
                detection_frame = image_np_expanded.copy()
                viz_utils.visualize_boxes_and_labels_on_image_array(
                    frame,
                    detections["detection_boxes"],
                    detections["detection_classes"],
                    detections["detection_scores"],
                    self.category_index,
                    use_normalized_coordinates=True,
                    min_score_thresh=0.30,
                )
                # Saves for video
                out.write(frame)
                # Display the resulting frame
                cv2.imshow('Charving Detection', frame)
                # Close window when "Q" button pressed
                # Close window when "Q" button pressed
                if cv2.waitKey(1) & 0xFF == ord('q'):
                    break
                
                percent = (self.starting_frame/frame_amount)*100
                print(str(percent) + "%")
                self.starting_frame = self.starting_frame + 1
            else:
                break
        # When everything done, release the video capture and video write objects
        cap.release()
        out.release()
        # Closes all the frames
        cv2.destroyAllWindows()
