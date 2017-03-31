package plugin.anatomical;

import org.json.JSONObject;

/**
 * Created by graysonsharpe on 3/23/17.
 */

public class AnatomyImage {

    private JSONObject _sourceObj;
    private String _folderPath;
    private int _layerLevel;
    private int _angleNumber;


    public AnatomyImage(JSONObject obj, String folderPath, int layerLevel, int angleNumber) {
        _sourceObj = obj;
        _folderPath = folderPath;
        _layerLevel = layerLevel;
        _angleNumber = angleNumber;
    }

    @Override
    public String toString() {
        return "AnatomyImage{" +
                "_sourceObj=" + _sourceObj +
                ", _folderPath='" + _folderPath + '\'' +
                ", _height=" + this.getHeight() +
                ", _width=" + this.getWidth() +
                ", _layerLevel=" + _layerLevel +
                ", _angleNumber=" + _angleNumber +
                ", _size='" + this.getSize() + '\'' +
                ", _sourceUrl='" + this.getSourceUrl() + '\'' +
                '}';
    }

    public JSONObject getSourceObj() {
        return _sourceObj;
    }

    public String getFolderPath() {
        return _folderPath;
    }

    public int getLayerLevel() {
        return _layerLevel;
    }

    public int getAngleNumber() {
        return _angleNumber;
    }

    public double getHeight() {
        return _sourceObj.optDouble("nH");
    }

    public double getWidth() {
        return _sourceObj.optDouble("nW");
    }

    public String getSize() {
        return _sourceObj.optString("nB");
    }

    public String getSourceUrl() {
        return _sourceObj.optString("sUrl");
    }
}
