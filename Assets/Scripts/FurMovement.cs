using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class FurMovement : MonoBehaviour{
    const string BENDDIRECTION = "_BendDirection";

    public float power = 1;
    public float speed = 1;
    
    [Space]
    public bool useGravity;
    public Vector3 customGravity = new Vector3(0, 0.1f, 0);

    [Space]
    public Material mat;

    Vector3 prevVal;
    Vector3 currentPos;
    Vector3 prevPos;

    void OnEnable(){
        prevVal = mat.GetVector(BENDDIRECTION);
    }

    void Start(){
        currentPos = transform.position;
        prevPos = currentPos;
    }

    void Update(){
        currentPos = transform.position;
        Vector3 heading = prevPos - currentPos;

        heading *= power;
        if(useGravity){
            heading -= customGravity; 
        }

        Vector3 current = mat.GetVector(BENDDIRECTION);
        Vector3 bending = Vector3.Lerp(current, -heading, Time.deltaTime * speed);
        mat.SetVector(BENDDIRECTION, bending);
        prevPos = currentPos;
    }

    void OnDisable(){ 
        mat.SetVector(BENDDIRECTION, prevVal);
    }
}
