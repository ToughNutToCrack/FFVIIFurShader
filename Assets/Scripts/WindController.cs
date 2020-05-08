using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class WindController : MonoBehaviour{
    const string BENDDIRECTION = "_BendDirection";
    
    public Vector3 axis = Vector3.forward;
    public float offset = 0.1f;
    public float mult = 0.5f;
    public float scale = 10; 
    [Space]
    public bool freezeX;
    public bool freezeY;
    public bool freezeZ;
    [Space]
    public List<Material> mats;

    List<Vector3> prevVal;

    void OnEnable(){
        prevVal = new List<Vector3>();
        foreach (var m in mats){
            prevVal.Add(m.GetVector(BENDDIRECTION));
        } 
    }

    void Update(){
        float val = offset + mult * Mathf.Sin(Time.time/scale) ;
    
        for(int i=0; i<mats.Count; i++){
            Vector3 dir = val * axis;
            dir = new Vector3(
                freezeX ? prevVal[i].x : dir.x, 
                freezeY ? prevVal[i].y : dir.y, 
                freezeZ ? prevVal[i].z : dir.z 
            );

            mats[i].SetVector(BENDDIRECTION, dir);
        }        
    }

    void OnDisable(){
        for(int i=0; i<mats.Count; i++){
           mats[i].SetVector(BENDDIRECTION, prevVal[i]);
        } 
    }
}
