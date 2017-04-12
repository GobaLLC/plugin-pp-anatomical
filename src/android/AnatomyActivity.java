package plugin.anatomical;

import android.app.Activity;
import android.app.ProgressDialog;
import android.content.Context;
import android.content.ContextWrapper;
import android.content.res.Resources;
import android.graphics.Bitmap;
import android.graphics.Matrix;
import android.graphics.Point;
import android.graphics.drawable.Drawable;
import android.os.Bundle;
import android.os.Handler;
import android.os.Message;
import android.text.TextUtils;
import android.util.Log;
import android.view.GestureDetector;
import android.view.MenuItem;
import android.view.MotionEvent;
import android.view.View;
import android.view.ViewGroup;
import android.view.ViewTreeObserver;
import android.widget.Button;
import android.widget.FrameLayout;
import android.widget.ImageView;
import android.widget.RelativeLayout;
import android.widget.TextView;
import android.widget.Toast;

import com.squareup.picasso.Picasso;

import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import java.io.File;
import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import java.util.Set;

public class AnatomyActivity extends Activity {

    private Context mContext;

    private GestureDetector mDetector;

    private static final String LAYERS_KEY = "aLayers";
    private static final String ANGLES_KEY = "aAngles";
    private static final String IMAGE_NAME = "image.jpg";

    private RelativeLayout mActivityLayout;
    private FrameLayout mContainer;
    private ImageView mGenderButton;
    private Button mBackButton;
    private TextView mTitle;
    private ProgressDialog mProgressDialog;

    private JSONObject _jsonData;
    private String _anatomyName;
    private String _anatomyIdentifier;
    private String _folderName;
    private String _imagePath;
    private String _folderPath;
    private File _storageFolder;

    private ArrayList<AnatomyImage> _maleAnatomyImages;
    private ArrayList<AnatomyImage> _femaleAnatomyImages;
    private ArrayList<File> _fileNames;

    private String _currentGender;
    private String _imageResolution;

    private Point _prevPoint;
    private boolean _showOneGender;

    private int _totalMaleLayers;
    private int _totalAnglesPerMaleLayer;
    private int _currentMaleFrame;
    private int _currentMaleLayer;
    private float _currentMaleLayerValue;

    private int _totalFemaleLayers;
    private int _totalAnglesPerFemaleLayer;
    private int _currentFemaleFrame;
    private int _currentFemaleLayer;
    private float _currentFemaleLayerValue;

    private int _totalLayers;
    private int _totalAngles;
    private int _currentFrame;
    private int _currentLayer;
    private String _prevTag;
    private float _currentLayerValue;

    private float _numberOfImagesLoaded;
    private float _totalImagesToDownload;

    public static int GENDER_FEMALE = 1;
    public static int GENDER_MALE = 2;

    private int _selectedGender;

    private Matrix translate;


    private String mURL = "http://www.allindiaflorist.com/imgs/arrangemen4.jpg";
    private String urls = "http://api.androidhive.info/images/sample.jpg";
    private String[] urlArray = {mURL, urls};


    private static final float FRAME_ROTATION_TOLERANCE = 15.0f;
    private static final float LAYER_TRANSITION_TOLERANCE = 10.0f;

    final Set<AnatomyImageDownloader> protectedFromGarbageCollectorTargets = new HashSet<AnatomyImageDownloader>();

    private static final int FRAME_BUFFER = 3;
    private static final int LAYER_BUFFER = 3;
    private int rotationBuffer = FRAME_BUFFER;
    private int layerBuffer = LAYER_BUFFER;


    @Override
    public void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

        final String package_name = getApplication().getPackageName();
        final Resources resources = getApplication().getResources();
        setContentView(resources.getIdentifier("layout_anatomy_activity", "layout", package_name));

        mContext = this;

        translate = new Matrix();

        mActivityLayout = (RelativeLayout) findViewById(resources.getIdentifier("layout_activity", "id", package_name));
        mContainer = (FrameLayout) findViewById(resources.getIdentifier("container", "id", package_name));
        mGenderButton = (ImageView) findViewById(resources.getIdentifier("button_gender", "id", package_name));
        mTitle = (TextView) findViewById(resources.getIdentifier("title", "id", package_name));
        mBackButton = (Button) findViewById(resources.getIdentifier("button_back", "id", package_name));

        mDetector = new GestureDetector(mContext, new GestureListener());
        mActivityLayout.setOnTouchListener(new View.OnTouchListener() {
            @Override
            public boolean onTouch(View view, MotionEvent motionEvent) {
                mDetector.onTouchEvent(motionEvent);
                return true;
            }
        });

        String jsonExtra = getIntent().getStringExtra("jsonData");

        try {
            _jsonData = new JSONObject(jsonExtra);
        } catch (JSONException e) {
            e.printStackTrace();
        }
        Log.d("JSON_DATA", _jsonData.toString());

        _maleAnatomyImages = new ArrayList<AnatomyImage>();
        _femaleAnatomyImages = new ArrayList<AnatomyImage>();
        _fileNames = new ArrayList<File>();

        _anatomyName = _jsonData.optString("sTitle");
        _anatomyIdentifier = _jsonData.optString("nID");

        mTitle.setText(_anatomyName);
        mBackButton.setText("< Back");

        _currentLayerValue = 0.0f;
        _currentLayer = 0;
        _currentFrame = 0;

        _selectedGender = AnatomyActivity.GENDER_FEMALE;

        if (1 == 1)
            _imageResolution = "15";
        else
            _imageResolution = "20";

        _folderName = _anatomyIdentifier;


        ContextWrapper cw = new ContextWrapper(mContext);
        String name_ = "foldername"; //Folder name in device android/data/
        File sd = cw.getDir(name_, Context.MODE_PRIVATE);

        _storageFolder = new File(sd, _folderName);
        _folderPath = _storageFolder.getAbsolutePath();

        mContainer.getViewTreeObserver().addOnGlobalLayoutListener(new ViewTreeObserver.OnGlobalLayoutListener() {
            @Override
            public void onGlobalLayout() {
                RelativeLayout.LayoutParams _rootLayoutParams = new RelativeLayout.LayoutParams(mContainer.getWidth(), mContainer.getWidth());
                _rootLayoutParams.addRule(RelativeLayout.BELOW, resources.getIdentifier("title", "id", package_name));
                mContainer.setLayoutParams(_rootLayoutParams);
                mContainer.getViewTreeObserver().removeOnGlobalLayoutListener(this);
            }
        });
    }

    @Override
    protected void onResume() {
        super.onResume();

        if(mContainer.getChildCount() > 0){
            return;
        }

        parseAnatomyData(_jsonData);

        ArrayList<AnatomyImage> anatomyImagesToDownload = new ArrayList<AnatomyImage>();
        anatomyImagesToDownload.addAll(_maleAnatomyImages);
        anatomyImagesToDownload.addAll(_femaleAnatomyImages);
        downloadImagesToDisk(anatomyImagesToDownload);
    }

    private void onResetLocation() {
        translate.reset();
    }

    private void onMove(float dx, float dy) {
        translate.postTranslate(dx, dy);
    }


    private void parseAnatomyData(JSONObject jsonObject) {
        _totalMaleLayers = 0;
        _totalAnglesPerMaleLayer = 0;

        _totalFemaleLayers = 0;
        _totalAnglesPerFemaleLayer = 0;

        JSONArray aLayers = jsonObject.optJSONArray(LAYERS_KEY);
        if (aLayers.length() == 0) {
            Log.e("ERROR", "ERROR: Critical error has occurred. No Data is present.");
            Toast.makeText(mContext, "There is no layer data available for this model.", Toast.LENGTH_SHORT).show();
        }

        int layerIndex = 0;
        for (int i = 0; i < aLayers.length(); i++) {
            JSONObject layerObj = aLayers.optJSONObject(i);
            String layerFolderName = _folderName + "/L" + String.format("%02d", layerIndex);

            String maleJsonKey = ANGLES_KEY + AnatomyActivity.GENDER_MALE;
            JSONArray aAngles1 = layerObj.optJSONArray(maleJsonKey);
            if (aAngles1.length() == 0) {
                Log.e("ERROR", "ERROR: No angle data is present at Male layer " + layerIndex);
            }

            int angleIndex = 0;
            for (int j = 0; j < aAngles1.length(); j++) {
                JSONObject angleObj = aAngles1.optJSONObject(j);
                String angleFolderName = layerFolderName + "/male/" + String.format("%02d", j);
                JSONObject angleResolutionObj = angleObj.optJSONObject(_imageResolution);
                AnatomyImage anatomyImage = new AnatomyImage(angleResolutionObj, angleFolderName, layerIndex, angleIndex);
                _maleAnatomyImages.add(anatomyImage);
                angleIndex++;
            }

            if (angleIndex > 0) {
                if (_totalAnglesPerMaleLayer > 0)
                    _totalAnglesPerMaleLayer = Math.min(_totalAnglesPerMaleLayer, angleIndex);
                else
                    _totalAnglesPerMaleLayer = angleIndex;

                _totalMaleLayers++;
            }


            String femaleJsonKey = ANGLES_KEY + AnatomyActivity.GENDER_FEMALE;
            JSONArray aAngles2 = layerObj.optJSONArray(femaleJsonKey);
            if (aAngles2.length() == 0) {
                Log.e("ERROR", "ERROR: No angle data is present at Female layer " + layerIndex);
            }

            angleIndex = 0;
            for (int j = 0; j < aAngles2.length(); j++) {
                JSONObject angleObj = aAngles2.optJSONObject(j);
                String angleFolderName = layerFolderName + "/female/" + String.format("%02d", j);
                JSONObject angleResolutionObj = angleObj.optJSONObject(_imageResolution);
                AnatomyImage anatomyImage = new AnatomyImage(angleResolutionObj, angleFolderName, layerIndex, angleIndex);
                _femaleAnatomyImages.add(anatomyImage);
                angleIndex++;
            }

            if (angleIndex > 0) {
                if (_totalAnglesPerFemaleLayer > 0)
                    _totalAnglesPerFemaleLayer = Math.min(_totalAnglesPerFemaleLayer, angleIndex);
                else
                    _totalAnglesPerFemaleLayer = angleIndex;

                _totalFemaleLayers++;
            }

            layerIndex++;
        }

        _totalImagesToDownload = _maleAnatomyImages.size() + _femaleAnatomyImages.size();
    }

    private void downloadImagesToDisk(ArrayList<AnatomyImage> anatomyImagesToDownload) {
        mProgressDialog = new ProgressDialog(AnatomyActivity.this);
        mProgressDialog.setMax((int) _totalImagesToDownload);
        mProgressDialog.setMessage("Loading images....");
        mProgressDialog.setTitle(_anatomyName);
        mProgressDialog.setProgressStyle(ProgressDialog.STYLE_HORIZONTAL);
        mProgressDialog.show();
        for (AnatomyImage anatomyImage : anatomyImagesToDownload) {

            final AnatomyImageDownloader downloader = new AnatomyImageDownloader(mContext, anatomyImage);
            protectedFromGarbageCollectorTargets.add(downloader);
            downloader.downloadImage();
            downloader.setOnImageDownloadListener(new OnImageDownloadListener() {
                @Override
                public void onBitmapLoaded(Bitmap bitmap, Picasso.LoadedFrom from) {
                    handleImageDownloadCompletion(downloader);
                }

                @Override
                public void onBitmapFailed(Drawable errorDrawable) {
                    handleImageDownloadCompletion(downloader);
                }
            });
        }
    }

    Handler handle = new Handler() {
        @Override
        public void handleMessage(Message msg) {
            super.handleMessage(msg);
            mProgressDialog.incrementProgressBy(1);
        }
    };

    private void handleImageDownloadCompletion(AnatomyImageDownloader downloader) {
        handle.sendMessage(handle.obtainMessage());
        protectedFromGarbageCollectorTargets.remove(downloader);
        Log.d("IMAGES LEFT", "IMAGES LEFT " + protectedFromGarbageCollectorTargets.size());
        if (protectedFromGarbageCollectorTargets.size() == 0) {
            runOnUiThread(new Runnable() {
                @Override
                public void run() {
                    setupLevels();
                    mProgressDialog.dismiss();
                }
            });
        }
    }

    @Override
    public boolean onOptionsItemSelected(MenuItem item) {
        switch (item.getItemId()) {
            case android.R.id.home:
                onBackPressed();
                return true;
        }
        return false;
    }

    @Override
    public void onBackPressed() {
        super.onBackPressed();
        finish();
    }

    public void backButtonPressed(View v) {
        finish();
    }

    public void genderButtonPressed(View v) {
        String package_name = getApplication().getPackageName();
        Resources resources = getApplication().getResources();

        if (_selectedGender == AnatomyActivity.GENDER_MALE) {
            _selectedGender = AnatomyActivity.GENDER_FEMALE;
            mGenderButton.setImageResource(resources.getIdentifier("icon_female", "drawable", package_name));
        } else {
            _selectedGender = AnatomyActivity.GENDER_MALE;
            mGenderButton.setImageResource(resources.getIdentifier("icon_male", "drawable", package_name));
        }
        setupLevels();
    }

    private void setupLevels() {
        if ((_totalMaleLayers == 0 && _totalFemaleLayers > 0) ||
                (_totalMaleLayers > 0 && _totalFemaleLayers == 0)) {
            _showOneGender = true;
            mGenderButton.setVisibility(View.INVISIBLE);
        } else {
            _showOneGender = false;
            mGenderButton.setVisibility(View.VISIBLE);
        }

        mContainer.removeAllViews();

        if (_selectedGender == AnatomyActivity.GENDER_MALE) {
            _currentGender = "male";
            _totalLayers = _totalMaleLayers;
            _totalAngles = _totalAnglesPerMaleLayer;

            _currentFemaleLayer = _currentLayer;
            _currentFemaleFrame = _currentFrame;
            _currentFemaleLayerValue = _currentLayerValue;

            _currentLayer = _currentMaleLayer;
            _currentFrame = _currentMaleFrame;
            _currentLayerValue = _currentMaleLayerValue;
        } else {
            _currentGender = "female";
            _totalLayers = _totalFemaleLayers;
            _totalAngles = _totalAnglesPerFemaleLayer;

            _currentMaleLayer = _currentLayer;
            _currentMaleFrame = _currentFrame;
            _currentMaleLayerValue = _currentLayerValue;

            _currentLayer = _currentFemaleLayer;
            _currentFrame = _currentFemaleFrame;
            _currentLayerValue = _currentFemaleLayerValue;
        }

        _currentLayerValue = 0.0f;
        _currentLayer = 0;
        _currentFrame = 0;

        for (int i = (_totalLayers - 1); i >= 0; i--) {
            addImageViewToLayer(i, _currentFrame);
        }
    }

    private void addImageViewToLayer(int layerLevel, int frameNum) {
        int nextLayer = Math.min(_currentLayer + 1, _totalAngles);

        List<String> paths = new ArrayList<String>();
        paths.add(_folderPath);
        paths.add(String.format("L%02d", layerLevel));
        paths.add(_currentGender);
        paths.add(String.format("%02d", frameNum));
        paths.add(IMAGE_NAME);

        String filePath = TextUtils.join("/", paths);

        ImageView imageView = new ImageView(mContext);
        imageView.setTag("imageview" + (layerLevel + 1));
        ViewGroup.LayoutParams layoutParams = new ViewGroup.LayoutParams(mContainer.getWidth(), mContainer.getWidth());
        imageView.setLayoutParams(layoutParams);

        if (_currentLayer == layerLevel) {
            float alpha = nextLayer - _currentLayerValue;
            imageView.setAlpha(alpha);
        } else {
            imageView.setAlpha(1.0f);
        }
        mContainer.addView(imageView);

        File myImageFile = new File(filePath);
        Picasso.with(this).load(myImageFile).into(imageView);
    }

    private void updateAnatomyImageLayer(int nextLayer, int layerAfterNext){
        String picassoTag = "picassoTag";

        ArrayList<Integer> layersToProcess = new ArrayList<Integer>();
        layersToProcess.add(nextLayer);
        layersToProcess.add(layerAfterNext);

        for (Integer layer : layersToProcess) {
            List<String> paths = new ArrayList<String>();
            paths.add(_folderPath);
            paths.add(String.format("L%02d", layer));
            paths.add(_currentGender);
            paths.add(String.format("%02d", _currentFrame));
            paths.add(IMAGE_NAME);
            String filePath = TextUtils.join("/", paths);
            File myImageFile = new File(filePath);

            ImageView imageView = getCurrentAnatomyImageView(layer);
            if(imageView == null){
                continue;
            }

            Picasso.Priority priority;
            if(layer==nextLayer)
                priority = Picasso.Priority.HIGH;
            else
                priority = Picasso.Priority.LOW;

            Picasso.with(mContext.getApplicationContext()).load(myImageFile).noFade().noPlaceholder().priority(priority).tag(picassoTag).into(imageView);
        }
    }


    private void updateAnatomyImageFrame(int nextFrame, int frameAfterNext) {

        String picassoTag = "picassoTag";
//        Picasso.with(mContext).cancelTag(picassoTag);
        ArrayList<Integer> layersToProcess = new ArrayList<Integer>();
        for(int j = _currentLayer; j <= _totalLayers - 1; j++){
            if(layersToProcess.size() < 2)
                layersToProcess.add(j);
        }
//
        if(_currentLayer != 0) {
            for (int k = 0; k < _currentLayer; k++) {
                if(layersToProcess.size() < 2)
                    layersToProcess.add(k);
            }
        }

        int i=0;
//        for (int i = (_totalLayers - 1); i >= 0; i--) {
        for (Integer layer : layersToProcess) {
            if (nextFrame >= _totalAngles) {
                _currentFrame = 0;
                frameAfterNext = _currentFrame + 1;
            } else if (nextFrame < 0) {
                _currentFrame = _totalAngles - 1;
                frameAfterNext = _currentFrame - 1;
            } else {
                _currentFrame = nextFrame;
            }

            //        NSLog(@"current frame %d,   nextIndex: %d", _currentFrame, nextFrame);

            List<String> paths = new ArrayList<String>();
            paths.add(_folderPath);
            paths.add(String.format("L%02d", layer));
            paths.add(_currentGender);
            paths.add(String.format("%02d", _currentFrame));
            paths.add(IMAGE_NAME);
            String filePath = TextUtils.join("/", paths);
            File myImageFile = new File(filePath);


//            List<String> nextPaths = new ArrayList<String>();
//            nextPaths.add(_folderPath);
//            nextPaths.add(String.format("L%02d", i));
//            nextPaths.add(_currentGender);
//            nextPaths.add(String.format("%02d", frameAfterNext));
//            nextPaths.add(IMAGE_NAME);
//            String nextFilePath = TextUtils.join("/", nextPaths);
//            File myNextImageFile = new File(nextFilePath);

//            Picasso.Priority nextFramePriority = Picasso.Priority.NORMAL;
//            if(i==0)
//                nextFramePriority = Picasso.Priority.HIGH;
//            else
//                nextFramePriority = Picasso.Priority.LOW;

//            Picasso.with(mContext).load(myNextImageFile).priority(nextFramePriority).tag(picassoTag).fetch();


            ImageView imageView = getCurrentAnatomyImageView(layer);

            Picasso.Priority priority;
            if(layer==_currentLayer)
                priority = Picasso.Priority.HIGH;
            else
                priority = Picasso.Priority.LOW;

            Picasso.with(mContext.getApplicationContext()).load(myImageFile).noFade().noPlaceholder().priority(priority).tag(picassoTag).into(imageView);

            i++;
        }
    }

    private ImageView getCurrentAnatomyImageView(int index) {
        return (ImageView) mContainer.findViewWithTag("imageview" + (index + 1));
    }


    private class GestureListener extends GestureDetector.SimpleOnGestureListener {

        @Override
        public boolean onScroll(MotionEvent e1, MotionEvent e2,
                                float distanceX, float distanceY) {

            float xTranslation = -distanceX;
            float yTranslation = -distanceY;

//            float xTranslation = e1.getX() - e2.getX();
//            float yTranslation = e2.getY() - e2.getY();

            onMove(xTranslation, yTranslation);

            float[] values = new float[9];
            translate.getValues(values);
            float globalX = values[Matrix.MTRANS_X];
            float globalY = values[Matrix.MTRANS_Y];
//            Log.d("TRANSLATION", "distanceX: " + globalX + " distanceY: " + globalY);


//            Log.d("TRANSLATION", "distanceX: " + xTranslation + " distanceY: " + yTranslation);

            if (Math.abs(globalX) >= FRAME_ROTATION_TOLERANCE) {
//                if(rotationBuffer != 0){
//                    rotationBuffer--;
//                    return false;
//                }
//                else{
//                    rotationBuffer = FRAME_BUFFER;
//                }
//                Log.d("THRESHOLD FRAME", "distanceX: " + globalX + " distanceY: " + globalY);
                float nextFrame = _currentFrame - (globalX / FRAME_ROTATION_TOLERANCE);

                float frameAfterNext;
                if (_currentFrame > nextFrame)
                    frameAfterNext = nextFrame - 1;
                else
                    frameAfterNext = nextFrame + 1;
                updateAnatomyImageFrame((int) nextFrame, (int) frameAfterNext);

                Log.d("ROTATING FRAME", "rotating frame currentLayerValue: " + _currentLayerValue + " currentLayer: " + _currentLayer + " currentFrame: " + _currentFrame + " nextFrame: " + nextFrame);
                onResetLocation();
                return true;
            }

            if (Math.abs(globalY) >= LAYER_TRANSITION_TOLERANCE) {

//                if(layerBuffer != 0){
//                    layerBuffer--;
//                    return false;
//                }
//                else{
//                    layerBuffer = LAYER_BUFFER;
//                }

//                Log.d("THRESHOLD LAYER", "distanceX: " + globalX + " distanceY: " + globalY);

                String direction;
                float prevLayerValue = _currentLayerValue;
                _currentLayerValue = _currentLayerValue + ((globalY / LAYER_TRANSITION_TOLERANCE) * 0.1f);
                _currentLayerValue = Math.max(_currentLayerValue, 0.0f);
                _currentLayerValue = Math.min(_currentLayerValue, _totalLayers - 1);
                _currentLayer = (int) Math.floor((double) _currentLayerValue);

                if(prevLayerValue > _currentLayerValue)
                    direction = "up";
                else
                    direction = "down";

                Log.d("Direction", "direction " + direction);

                if (_currentLayer != (_totalLayers - 1)) {
                    int nextLayer = Math.min(_currentLayer + 1, _totalLayers);
                    ImageView currentImageView = getCurrentAnatomyImageView(_currentLayer);
                    float alpha = nextLayer - _currentLayerValue;
                    if (currentImageView != null) {

                        if(direction.equalsIgnoreCase("up")){
//                            if(alpha >= 0.51) {
                                ImageView prevImageView = (ImageView) mContainer.findViewWithTag("imageview" + (_currentLayer + 1));
                                ImageView prevAfterImageView = (ImageView) mContainer.findViewWithTag("imageview" + (_currentLayer + 2));
                                if (prevImageView != null) {
                                    Log.d("PrevImageAlpha", "prevImageView alpha " + prevImageView.getAlpha());
//                                    if (prevImageView.getAlpha() > 0.0) {
                                        prevImageView.setAlpha(1.0f);
//                                    prevImageView.setVisibility(View.GONE);
//                                        prevImageView.setVisibility(View.INVISIBLE);
//                                    }
                                }
                            if (prevAfterImageView != null) {
                                prevAfterImageView.setAlpha(1.0f);
                            }
//                            ImageView nextImageView = (ImageView) mContainer.findViewWithTag("imageview" + (_currentLayer - 1));
//                            if (nextImageView != null) {
////                                nextImageView.setVisibility(View.VISIBLE);
//                            }
                                updateAnatomyImageLayer(_currentLayer - 1, _currentLayer - 2);
//                            }
                        }
                        else {
//                            if(alpha < 0.49){
                                ImageView prevImageView = (ImageView) mContainer.findViewWithTag("imageview" + (_currentLayer - 1));
                                ImageView prevAfterImageView = (ImageView) mContainer.findViewWithTag("imageview" + (_currentLayer - 2));
                                if (prevImageView != null) {
                                    Log.d("PrevImageAlpha", "prevImageView alpha " + prevImageView.getAlpha());
//                                    if(prevImageView.getAlpha() > 0.0){
                                        prevImageView.setAlpha(0.0f);
//                                        prevImageView.setVisibility(View.INVISIBLE);
//                                    }
                                }
                            if (prevAfterImageView != null) {
                                prevAfterImageView.setAlpha(0.0f);
                            }
//                            ImageView nextImageView = (ImageView) mContainer.findViewWithTag("imageview" + (_currentLayer + 1));
//                            if (nextImageView != null) {
////                                nextImageView.setVisibility(View.VISIBLE);
//                            }
                                updateAnatomyImageLayer(_currentLayer + 1, _currentLayer + 2);
//                            }
                        }

                        Log.d("THRESHOLD LAYER", "currentLayerValue: " + _currentLayerValue + " currentLayer: " + _currentLayer + " nextLayer: " + nextLayer + " alpha: " + alpha);
                        currentImageView.setAlpha(alpha);
                        onResetLocation();

                        return true;
                    }
                }

                return false;
            }

            return false;
        }
    }

}
